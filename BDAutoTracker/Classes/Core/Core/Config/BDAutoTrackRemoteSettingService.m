//
//  BDAutoTrackRemoteSettingService.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRemoteSettingService.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackNotifications.h"

static NSString *const kBDAutoTrackBatchTimeInterval    = @"kBDAutoTrackBatchTimeInterval";
static NSString *const kBDAutoTrackBatchBulkSize    = @"kBDAutoTrackBatchBulkSize";
static NSString *const kBDAutoTrackABTestInterval       = @"kBDAutoTrackABTestInterval";
static NSString *const kBDAutoTrackABTestEnabled        = @"kBDAutoTrackABTestEnabled";
static NSString *const kBDAutoTrackUITrackerOff         = @"kBDAutoTrackUITrackerOff";
static NSString *const kBDAutoTrackSkipLauch            = @"kBDAutoTrackSkipLauch";
static NSString *const kBDAutoTrackRealTimeEvents       = @"kBDAutoTrackRealTimeEvents";
static NSString *const kBDAutoTrackSensitiveFields       = @"kBDAutoTrackSensitiveFields";

static const NSInteger kDefaultTrackerConfigFetchInterval  = 60 * 60 * 6;
static const NSInteger kMinTrackerConfigFetchInterval  = 60 * 30;
static NSString * const kBDAutoTrackFetchInterval = @"kBDAutoTrackFetchInterval";

@interface BDAutoTrackRemoteSettingService ()

@property (nonatomic, assign) NSTimeInterval batchInterval;
@property (nonatomic, assign) NSUInteger batchBulkSize;
@property (nonatomic, assign) NSTimeInterval abFetchInterval;
@property (nonatomic, assign) BOOL skipLaunch;
@property (atomic, copy) NSArray *realTimeEvents;
@property (atomic, copy) NSArray *sensitiveFields;

@property (nonatomic, strong) NSDictionary *rawConfig;

@end

@implementation BDAutoTrackRemoteSettingService

- (NSDictionary *)devtools_toDictionary
{
    return self.rawConfig;
}

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameRemote;
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
        CFTimeInterval interval = [defaults doubleValueForKey:kBDAutoTrackBatchTimeInterval];
            
        self.batchInterval = interval ?: 60.0f;
        
        self.batchBulkSize = [defaults integerValueForKey:kBDAutoTrackBatchBulkSize];
        
        self.abFetchInterval = MAX([defaults doubleValueForKey:kBDAutoTrackABTestInterval], 600.0);
        self.abTestEnabled = YES;
        if ([defaults objectForKey:kBDAutoTrackABTestEnabled]) {
            self.abTestEnabled = [defaults boolValueForKey:kBDAutoTrackABTestEnabled];
        }
        
        self.autoTrackEnabled = YES;
        if ([defaults objectForKey:kBDAutoTrackUITrackerOff]) {
            self.autoTrackEnabled = ![defaults boolValueForKey:kBDAutoTrackUITrackerOff];
        }

        self.skipLaunch = [defaults boolValueForKey:kBDAutoTrackSkipLauch];
        self.realTimeEvents = [defaults arrayValueForKey:kBDAutoTrackRealTimeEvents];
        NSInteger fetchInterval = [defaults integerValueForKey:kBDAutoTrackFetchInterval];
        self.fetchInterval = fetchInterval < kMinTrackerConfigFetchInterval ? kDefaultTrackerConfigFetchInterval : fetchInterval;
        
        self.sensitiveFields = [defaults arrayValueForKey:kBDAutoTrackSensitiveFields];
        
        
    }

    return self;
}

- (void)updateRemoteWithResponse:(NSDictionary *)responseDict {
    NSDictionary *config = [responseDict vetyped_dictionaryForKey:@"config"];
    if (config.count > 0) {
        self.rawConfig = config;
        
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];

        NSTimeInterval batchInterval = [config vetyped_doubleForKey:@"batch_event_interval"];
        
        if (batchInterval >= 5.0f && batchInterval <= 300.0f) {
            
        } else {
            batchInterval = 60.0f;
        }
        self.batchInterval = batchInterval;
        [defaults setValue:@(batchInterval) forKey:kBDAutoTrackBatchTimeInterval];
        
        NSUInteger batchBulkSize = [config vetyped_integerForKey:@"batch_event_size"];
        if (batchBulkSize >= 50 && batchInterval <= 10000.0f) {
          
        } else {
            batchBulkSize = 0;
        }
        self.batchBulkSize = batchBulkSize;
        [defaults setValue:@(batchBulkSize) forKey:kBDAutoTrackBatchBulkSize];
        
        
        NSTimeInterval abFetchInterval = MAX([config vetyped_doubleForKey:@"abtest_fetch_interval"], 600.0f);
        self.abFetchInterval = abFetchInterval;
        

        self.abTestEnabled = [config vetyped_boolForKey:@"bav_ab_config"];

        if ([config objectForKey:@"bav_log_collect"]) {
            BOOL autoTrackEabled = [config vetyped_boolForKey:@"bav_log_collect"];
            self.autoTrackEnabled = autoTrackEabled;
            [defaults setValue:@(!autoTrackEabled) forKey:kBDAutoTrackUITrackerOff];
        } else {
            [defaults setValue:nil forKey:kBDAutoTrackUITrackerOff];
            self.autoTrackEnabled = YES;
        }
        

        BOOL skipLaunch = ![config vetyped_boolForKey:@"send_launch_timely"];
        self.skipLaunch = skipLaunch;
        
        NSArray *realTimeEvents = [config vetyped_arrayForKey:@"real_time_events"];
        self.realTimeEvents = realTimeEvents;
        NSInteger fetchInterval = [config vetyped_integerForKey:@"fetch_interval"];
        fetchInterval = fetchInterval < kMinTrackerConfigFetchInterval ? kDefaultTrackerConfigFetchInterval : fetchInterval;
        self.fetchInterval = fetchInterval;
        
        NSArray *sensitiveFields = [config vetyped_arrayForKey:@"sensitive_fields"];
        self.sensitiveFields = sensitiveFields;
        [defaults setValue:sensitiveFields forKey:kBDAutoTrackSensitiveFields];
        
        NSDictionary *userInfo = @{kBDAutoTrackNotificationAppID: self.appID,
                                   kBDAutoTrackNotificationData: [responseDict copy]};
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackRemoteConfigDidUpdateNotification object:nil userInfo:userInfo];
        
        
        [defaults setValue:@(fetchInterval) forKey:kBDAutoTrackFetchInterval];
        [defaults setValue:@(abFetchInterval) forKey:kBDAutoTrackABTestInterval];
        [defaults setValue:@(self.abTestEnabled) forKey:kBDAutoTrackABTestEnabled];
        [defaults setValue:@(skipLaunch) forKey:kBDAutoTrackSkipLauch];
        [defaults setValue:[realTimeEvents copy] forKey:kBDAutoTrackRealTimeEvents];
       
        [defaults saveDataToFile];
    }
}

@end

BDAutoTrackRemoteSettingService *bd_remoteSettingsForAppID(NSString *appID) {
    BDAutoTrackRemoteSettingService *settings = (BDAutoTrackRemoteSettingService *)bd_standardServices(BDAutoTrackServiceNameRemote,appID);
    if ([settings isKindOfClass:[BDAutoTrackRemoteSettingService class]]) {
        return settings;
    }
    
    return nil;
}
