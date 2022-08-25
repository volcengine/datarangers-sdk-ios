//
//  BDAutoTrackSettingsRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//




#import "BDAutoTrackSettingsRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackBatchService.h"

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackServiceCenter.h"

#import "BDAutoTrackDeviceHelper.h"
#import "NSDictionary+VETyped.h"
#import "NSData+VECryptor.h"
#import "NSData+VEGZip.h"
#import "BDAutoTrack+Private.h"

static NSString * const kBDTrackerLastFetchTime = @"kBDTrackerLastFetchTime";

@interface BDAutoTrackSettingsRequest ()

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *iv;

@end

@implementation BDAutoTrackSettingsRequest

- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLSettings;
        self.key = [[NSUUID UUID].UUIDString substringToIndex:32];
        self.iv = [[NSUUID UUID].UUIDString substringToIndex:16];
        self.lastFetchTime = 0;
//        self.encrypt = YES;
    }

    return self;
}

- (NSString *)requestURL {
    NSString *url = [super requestURL];
    return bd_appendQueryToURL(url, kBDAutoTrackDecivcePlatform, bd_device_platformName());
}

/// 限制频率
- (void)startRequestWithRetry:(NSInteger)retry {
    long long fetchInterval = bd_remoteSettingsForAppID(self.appID).fetchInterval;
    long long now = [[NSDate date] timeIntervalSince1970];
    if (now < self.lastFetchTime + fetchInterval) {
        return;
    }
    self.lastFetchTime = now;
    [super startRequestWithRetry:retry];
}

- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = bd_isValidResponse(responseDict);
    if (success) {
        long long now = [[NSDate date] timeIntervalSince1970];
        self.lastFetchTime = now;
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] setValue:@(now) forKey:kBDTrackerLastFetchTime];
        NSString *appID = self.appID;
        BDAutoTrackRemoteSettingService *settings = bd_remoteSettingsForAppID(appID);
        [settings updateRemoteWithResponse:responseDict];
        BOOL abTestEnabledRemote = settings.abTestEnabled;
        
        [BDAutoTrack trackWithAppID:self.appID].abtestManager.abtestEnabled = abTestEnabledRemote;
        
        bd_batchUpdateTimer(settings.batchInterval, settings.skipLaunch, appID);
        bd_updateServerTime(responseDict);
        
    } else {
        self.lastFetchTime = 0;
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] setValue:@(0) forKey:kBDTrackerLastFetchTime];
    }
    /// 不重试
    return YES;
}

- (NSMutableDictionary *)requestParameters {
    NSMutableDictionary *result = [super requestParameters];
    if (self.encrypt) {
        [result setValue:self.key forKey:@"key"];
        [result setValue:self.iv forKey:@"iv"];
    }
    
    if (bd_settingsServiceForAppID(self.appID).eventFilterEnabled) {
        [result setValue:@(1) forKey:@"event_filter"];
    }
    
    return result;
}

- (NSDictionary *)responseFromData:(NSData *)data error:(NSError *)error {
    NSDictionary *result = nil;
    if (self.encrypt) {
        if (data != nil && error == nil) {
            NSData *decryptData = [data veaes_decryptWithKey:self.key size:VEAESKeySizeAES256 iv:self.iv];
            if ([decryptData ve_isGzipCompressedData]) {
                decryptData = [decryptData ve_dataByGZipDecompressingDataWithError:nil];
            }
            
            if (decryptData != nil) {
                result = applog_JSONDictionanryForData(decryptData);
            }
        }
        
    }
    
    /* result == nil:
     * either the encrypt switch is not enabled or
     * the decryption fails (possibly the back data is not encrypted)
     */
    if (result == nil) {
        result = [super responseFromData:data error:error];
    }
    NSString *appID = self.appID;
    if (bd_settingsServiceForAppID(appID).eventFilterEnabled) {
        NSDictionary *eventList = [[result vetyped_dictionaryForKey:@"config"] vetyped_dictionaryForKey:@"event_list"];
        id<BDAutoTrackFilterService> service = (id<BDAutoTrackFilterService>)bd_standardServices(BDAutoTrackServiceNameFilter, appID);
        [service updateBlockList:eventList save:YES];
    }
    
    
    return result;
}


@end
