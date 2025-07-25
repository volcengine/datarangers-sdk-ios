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
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrack+Private.h"
#import "RangersLog.h"
#import "BDAutoTrackRegisterService.h"
#import "RangersRouter.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDCommonEnumDefine.h"
#import "NSDictionary+VETyped.h"

@interface BDAutoTrackProfileReporter () {
    NSLock  *reportLocker;
}
@property (nonatomic) NSString *appID;

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

- (void)sendProfileTrack {
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    
    RL_DEBUG(tracker, @"Profile", @"profile batch start.");
    if (![self->reportLocker tryLock]) {
        RL_DEBUG(tracker, @"Profile", @"profile batch terminate due to BUSY.");
        return;
    }
    
    if (!bd_registerServiceAvailableForAppID(self.appID)) {
        RL_WARN(tracker, @"Profile", @"profile batch terminate due to NOT Register successful.");
        [self->reportLocker unlock];
        return;
    }
    
    NSArray <NSDictionary *> *profileTracks = [bd_databaseServiceForAppID(self.appID) profileTracks];
    if (profileTracks.count < 1) {
        RL_INFO(tracker, @"Profile", @"profile batch terminate due to NO DATA.");
        [self->reportLocker unlock];
        return;
    }
    
    NSMutableArray<NSDictionary *> *tracks = [NSMutableArray new];
    __block id block_flag;
    __block id user_unique_id;
    __block id user_unique_id_type;
    __block NSString *IMPORTANT_SSID;
    [profileTracks enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block_flag = @"in block";
        if (!user_unique_id) {
            user_unique_id = [obj objectForKey:kBDAutoTrackEventUserID];
            user_unique_id_type = [obj objectForKey:kBDAutoTrackEventUserIDType];
        }
        
        id _uuid = [obj objectForKey:kBDAutoTrackEventUserID];
        if (user_unique_id == [NSNull null]) {
            if (_uuid == [NSNull null]) {
                if (IMPORTANT_SSID.length == 0 ) {
                    IMPORTANT_SSID = [obj vetyped_stringForKey:kBDAutoTrackSSID];
                }
                [tracks addObject:obj];
            }
        } else if ([user_unique_id isKindOfClass:NSString.class]) {
            if ([_uuid isKindOfClass:NSString.class] && [user_unique_id isEqualToString:_uuid]) {
                if (IMPORTANT_SSID.length == 0 ) {
                    IMPORTANT_SSID = [obj vetyped_stringForKey:kBDAutoTrackSSID];
                }
                [tracks addObject:obj];
            }
        }
    }];
    profileTracks = [tracks copy];
    
    if (IMPORTANT_SSID.length == 0) {
        NSString *ssid = [RangersRouter sync:[RangersRouting routing:@"ssid"
                                                                base:self.appID
                                                          parameters:@{
            kBDAutoTrackEventUserID: user_unique_id?:[NSNull null],
            kBDAutoTrackEventUserIDType: user_unique_id_type?:[NSNull null]
        }]];
        IMPORTANT_SSID = ssid;
    }
    
    NSMutableDictionary *HTTPBody = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *header = bd_requestPostHeaderParameters(self.appID);
    bd_addABVersions(HTTPBody, self.appID);
    
    [HTTPBody setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
#if TARGET_OS_IOS
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    [header setValue:[track.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    
    if (IMPORTANT_SSID.length > 0) {
        [header setValue:IMPORTANT_SSID forKey:kBDAutoTrackSSID];
    }
    
    if ([block_flag isKindOfClass:NSString.class]) {
        NSString *userIDString = (NSString *)user_unique_id;
        [header setValue:userIDString forKey:kBDAutoTrackEventUserID];
        NSString *userIDTypeString = (NSString *)user_unique_id_type;
        [header setValue:userIDTypeString forKey:kBDAutoTrackEventUserIDType];
    }
    
    [header bdheader_keyFormat];
    [HTTPBody setValue:header forKey:kBDAutoTrackHeader];
    [HTTPBody setValue:[track.localConfig serverTime] forKey:kBDAutoTrackTimeSync];
    [HTTPBody setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];
    
    
    NSArray <NSDictionary *> *processedProfileTracks = [self processedProfileTracks:profileTracks];
    [HTTPBody setValue:processedProfileTracks forKey:BDAutoTrackTableEventV3];  // 上报的时候依然挂在event_v3顶层键下面

    NSString *appID = self.appID;
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLProfile appID:appID];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appID);
    __weak typeof(self) wself = self;
    BDAutoTrackNetworkFinishBlock finishBlock = ^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        if (![self->reportLocker tryLock]) {
            [self->reportLocker unlock];
        }
        if (error) {
            RL_ERROR(tracker, @"Profile", @"profile batch failure. (%@)", error.localizedFailureReason);
            return;
        }
        __strong typeof(wself) self = wself;
        NSDictionary *responseDict = applog_JSONDictionanryForData(data);
        if ([responseDict[kBDAutoTrackMessage] isEqualToString:BDAutoTrackMessageSuccess]) {
            NSArray <NSString *> *trackIDs = [self trackIDsFromProfileTracks:profileTracks];
            RL_DEBUG(tracker, @"Profile", @"profile batch successful [%d].",trackIDs.count);
            bd_databaseRemoveTracks(@{
                BDAutoTrackTableProfile: trackIDs
            }, self.appID);
            
            if (tracker.eventBlock) {
                [profileTracks enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *event = [obj objectForKey:@"event"];
                    tracker.eventBlock(BDAutoTrackEventStatusReported, BDAutoTrackEventAllTypeProfile, event, obj);
                }];
            }
            
            [self sendProfileTrackIfNeed];  //make sure profile data flush
        } else {
            RL_ERROR(tracker, @"Profile", @"profile batch failure. (%@)", responseDict);
        }
    };
    
    RL_DEBUG(tracker, @"Profile", @"profile batch request[%d] (%@).",profileTracks.count, requestURL);
    
    
    NSDictionary *requestBody = bd_filterSensitiveParameters(HTTPBody, self.appID);
    bd_handleCommonParamters(requestBody, self.associatedTrack, BDAutoTrackRequestURLProfile);
    bd_network_asyncRequestForURL(requestURL,
                                  @"POST",
                                  30.0f,
                                  bd_headerField(appID),
                                  requestBody,
                                  self.associatedTrack.networkManager,
                                  finishBlock);
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
