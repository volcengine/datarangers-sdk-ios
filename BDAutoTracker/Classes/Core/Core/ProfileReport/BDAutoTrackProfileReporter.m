//
//  BDAutoTrackProfileReporter.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackProfileReporter.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackURLHostProvider.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrack+Private.h"
#import "RangersLog.h"
#import "RangersRouter.h"

@interface BDAutoTrackProfileReporter () {
    NSLock  *reportLocker;
}
@property (nonatomic) NSString *appID;

/// appID关联的track实例
@property (nonatomic, weak) BDAutoTrack *associatedTrack;
@end

@implementation BDAutoTrackProfileReporter

- (instancetype)initWithAppID:(NSString *)appID associatedTrack:(BDAutoTrack *)track {
    self = [super init];
    if (self) {
        self.appID = appID;
        self.associatedTrack = track;
        reportLocker = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - public

- (void)sendProfileTrackIfNeed
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendProfileTrack];
    });
}

/// 立即上报Profile事件
- (void)sendProfileTrack {
    
    RL_DEBUG(self.appID, @"[Profile] profile batch start.");
    if (![self->reportLocker tryLock]) {
        RL_DEBUG(self.appID, @"[Profile] profile batch terminate due to BUSY.");
        return;
    }
    
    if (!self.associatedTrack.identifier.deviceAvalible) {
        RL_WARN(self.appID, @"[Profile] profile batch terminate due to NOT Register successful.");
        [self->reportLocker unlock];
        return;
    }
    
    NSArray <NSDictionary *> *profileTracks = [bd_databaseServiceForAppID(self.appID) profileTracks];
    if (profileTracks.count < 1) {
        RL_DEBUG(self.appID, @"[Profile] profile batch terminate due to NO DATA.");
        [self->reportLocker unlock];
        return;
    }
    
    
    //清洗只保留1一个UUID
    NSMutableArray<NSDictionary *> *tracks = [NSMutableArray new];
    __block id user_unique_id;
    __block NSString *IMPORTANT_SSID;
    [profileTracks enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if (!user_unique_id) {
            user_unique_id = [obj objectForKey:kBDAutoTrackEventUserID];
        }
        if (IMPORTANT_SSID.length == 0 ) {
            IMPORTANT_SSID = [obj objectForKey:kBDAutoTrackSSID];
        }
        id _uuid = [obj objectForKey:kBDAutoTrackEventUserID];
        if (user_unique_id == [NSNull null]) {
            if (_uuid == [NSNull null]) {
                [tracks addObject:obj];
            }
        } else if ([user_unique_id isKindOfClass:NSString.class]) {
            if ([user_unique_id isEqualToString:_uuid]) {
                [tracks addObject:obj];
            }
        }
    }];
    profileTracks = [tracks copy];
    
    //fix ssid
    if (IMPORTANT_SSID.length == 0) {
        NSString *ssid = [RangersRouter sync:[RangersRouting routing:@"ssid"
                                                                base:self.appID
                                                          parameters:user_unique_id]];
        IMPORTANT_SSID = ssid;
    }
    
    /* prepare request */
    NSMutableDictionary *HTTPBody = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *header = bd_requestPostHeaderParameters(self.appID);
    /* ABVersions */
    bd_addABVersions(HTTPBody, self.appID);
    
    [HTTPBody setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
#if TARGET_OS_IOS
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    /* alink utm */
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    /* alink tracer_data */
    [header setValue:[track.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    
    if (IMPORTANT_SSID.length > 0) {
        [header setValue:IMPORTANT_SSID forKey:kBDAutoTrackSSID];
    }
    
    [HTTPBody setValue:header forKey:kBDAutoTrackHeader];
    [HTTPBody setValue:bd_timeSync() forKey:kBDAutoTrackTimeSync];
    [HTTPBody setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];
    
    
    NSArray <NSDictionary *> *processedProfileTracks = [self processedProfileTracks:profileTracks];
    [HTTPBody setValue:processedProfileTracks forKey:BDAutoTrackTableEventV3];  // 上报的时候依然挂在event_v3顶层键下面

    /* send request */
    NSString *appID = self.appID;
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLProfile appID:appID];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appID);
    __weak typeof(self) wself = self;
    BDAutoTrackNetworkFinishBlock finishBlock = ^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        if (![self->reportLocker tryLock]) {
            [self->reportLocker unlock];
        }
        if (error) {
            RL_ERROR(self.appID, @"[Profile] profile batch failure. (%@)", error.localizedFailureReason);
            return;
        }
        __strong typeof(wself) self = wself;
        NSDictionary *responseDict = applog_JSONDictionanryForData(data);
        if ([responseDict[kBDAutoTrackMessage] isEqualToString:BDAutoTrackMessageSuccess]) {
            NSArray <NSString *> *trackIDs = [self trackIDsFromProfileTracks:profileTracks];
            RL_DEBUG(self.appID, @"[Profile] profile batch successful [%d].",trackIDs.count);
            bd_databaseRemoveTracks(@{
                BDAutoTrackTableProfile: trackIDs
            }, self.appID);
        } else {
            RL_ERROR(self.appID, @"[Profile] profile batch failure. (%@)", responseDict);
        }
        [self sendProfileTrackIfNeed];  //make sure profile data flush
    };
    
    RL_DEBUG(self.appID, @"[Profile] profile batch request[%d] (%@).",profileTracks.count, requestURL);
    bd_network_asyncRequestForURL(requestURL,
                                  @"POST",
                                  bd_headerField(YES, appID),
                                  bd_settingsServiceForAppID(appID).logNeedEncrypt,
                                  YES,
                                  HTTPBody,
                                  finishBlock,
                                  [self encryptionDelegate]);
}

#pragma mark computed
- (id<BDAutoTrackEncryptionDelegate>)encryptionDelegate {
    return self.associatedTrack.encryptionDelegate;
}

#pragma mark - private
- (NSArray<NSString *> *)trackIDsFromProfileTracks:(NSArray <NSDictionary *> *)profileTracks {
    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] init];
    for (NSDictionary *profileTrack in profileTracks) {
        if ([profileTrack isKindOfClass:[NSDictionary class]] && profileTrack[kBDAutoTrackTableColumnTrackID]) {
            [result addObject:profileTrack[kBDAutoTrackTableColumnTrackID]];
        }
    }
    return result;
}

- (NSArray <NSDictionary *> *)processedProfileTracks:(NSArray <NSDictionary *> *)profileTracks {
    NSMutableArray <NSDictionary *> *result = [[NSMutableArray alloc] init];
    for (NSDictionary *profileTrack in profileTracks) {
        if ([profileTrack isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *newProfileTrack = [NSMutableDictionary dictionaryWithDictionary:profileTrack];
            [newProfileTrack removeObjectForKey:kBDAutoTrackTableColumnTrackID];
            [result addObject:newProfileTrack];
        }
    }
    return result;
}

@end
