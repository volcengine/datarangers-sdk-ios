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
#import "BDAutoTrackSettingsRequest.h"
#import "BDAutoTrackNotifications.h"

/// defaults key
static NSString *const kBDAutoTrackBatchTimeInterval    = @"kBDAutoTrackBatchTimeInterval";
static NSString *const kBDAutoTrackABTestInterval       = @"kBDAutoTrackABTestInterval";
static NSString *const kBDAutoTrackABTestEnabled        = @"kBDAutoTrackABTestEnabled";
static NSString *const kBDAutoTrackUITrackerOff         = @"kBDAutoTrackUITrackerOff";
static NSString *const kBDAutoTrackSkipLauch            = @"kBDAutoTrackSkipLauch";
static NSString *const kBDAutoTrackRealTimeEvents       = @"kBDAutoTrackRealTimeEvents";

static const NSInteger kDefaultTrackerConfigFetchInterval  = 60 * 60 * 6;
static const NSInteger kMinTrackerConfigFetchInterval  = 60 * 30;
static NSString * const kBDAutoTrackFetchInterval = @"kBDAutoTrackFetchInterval";

@interface BDAutoTrackRemoteSettingService ()

@property (nonatomic, assign) NSTimeInterval batchInterval;     /// batch_event_interval
@property (nonatomic, assign) NSTimeInterval abFetchInterval;   /// abtest_fetch_interval 目前后台没有下发，取值默认 600
@property (nonatomic, assign) BOOL skipLaunch;       /// send_launch_timely
@property (atomic, copy) NSArray *realTimeEvents;            /// real_time_events 目前没有实时上报通道
@property (nonatomic, strong) BDAutoTrackSettingsRequest *request;

@end

@implementation BDAutoTrackRemoteSettingService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameRemote;
        
        
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
        CFTimeInterval interval = [defaults doubleValueForKey:kBDAutoTrackBatchTimeInterval];
        self.batchInterval =  interval >= 20.0 ? interval : 60.0;
        self.abFetchInterval = MAX([defaults doubleValueForKey:kBDAutoTrackABTestInterval], 600.0);
        self.abTestEnabled = [defaults boolValueForKey:kBDAutoTrackABTestEnabled];
        self.autoTrackEnabled = ![defaults boolValueForKey:kBDAutoTrackUITrackerOff];
        self.skipLaunch = [defaults boolValueForKey:kBDAutoTrackSkipLauch];
        self.realTimeEvents = [defaults arrayValueForKey:kBDAutoTrackRealTimeEvents];
        NSInteger fetchInterval = [defaults integerValueForKey:kBDAutoTrackFetchInterval];
        self.fetchInterval = fetchInterval < kMinTrackerConfigFetchInterval ? kDefaultTrackerConfigFetchInterval : fetchInterval;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:) name:BDAutoTrackNotificationRegisterSuccess object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateRemoteWithResponse:(NSDictionary *)responseDict {
    NSDictionary *config = [responseDict vetyped_dictionaryForKey:@"config"];
    if (config.count > 0) {
        NSTimeInterval batchInterval = MAX([config vetyped_doubleForKey:@"batch_event_interval"], 20.0f);
        self.batchInterval = batchInterval;

        NSTimeInterval abFetchInterval = MAX([config vetyped_doubleForKey:@"abtest_fetch_interval"], 600.0f);
        self.abFetchInterval = abFetchInterval;
        
        BOOL abTestEnabledLocal = bd_settingsServiceForAppID(self.appID).abTestEnabled;
        BOOL abTestEnabled = [config vetyped_boolForKey:@"bav_ab_config"] && abTestEnabledLocal;
        self.abTestEnabled = abTestEnabled;
        [BDAutoTrack trackWithAppID:self.appID].abtestManager.abtestEnabled = abTestEnabled;


        BOOL autoTrackEabled = [config vetyped_boolForKey:@"bav_log_collect"];
        self.autoTrackEnabled = autoTrackEabled;

        BOOL skipLaunch = ![config vetyped_boolForKey:@"send_launch_timely"];
        self.skipLaunch = skipLaunch;
        
        
        if ([config vetyped_boolForKey:@"applog_disable_monitor"]) {
            [[BDAutoTrack trackWithAppID:self.appID].monitorAgent disable];
        }
        
        NSArray *realTimeEvents = [config vetyped_arrayForKey:@"real_time_events"];
        self.realTimeEvents = realTimeEvents;
        NSInteger fetchInterval = [config vetyped_integerForKey:@"fetch_interval"];
        fetchInterval = fetchInterval < kMinTrackerConfigFetchInterval ? kDefaultTrackerConfigFetchInterval : fetchInterval;
        self.fetchInterval = fetchInterval;
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        [defaults setValue:@(fetchInterval) forKey:kBDAutoTrackFetchInterval];
        [defaults setValue:@(batchInterval) forKey:kBDAutoTrackBatchTimeInterval];
        [defaults setValue:@(abFetchInterval) forKey:kBDAutoTrackABTestInterval];
        [defaults setValue:@(abTestEnabled) forKey:kBDAutoTrackABTestEnabled];
        [defaults setValue:@(!autoTrackEabled) forKey:kBDAutoTrackUITrackerOff];
        [defaults setValue:@(skipLaunch) forKey:kBDAutoTrackSkipLauch];
        [defaults setValue:[realTimeEvents copy] forKey:kBDAutoTrackRealTimeEvents];
        [defaults saveDataToFile];
    }
}

- (void)requestRemoteSettings
{
    long long fetchInterval = self.fetchInterval;
    long long now = [[NSDate date] timeIntervalSince1970];
    if (now < self.lastFetchTime + fetchInterval) {
        return;
    }
    self.lastFetchTime = now;
    [self.request startRequestWithRetry:1];
}

#pragma mark - noti

- (void)onRegisterSuccess:(NSNotification *)noti
{
    if (noti.userInfo && [BDAutoTrackNotificationDataSourceServer isEqualToString:noti.userInfo[kBDAutoTrackNotificationDataSource]]) {
        [self requestRemoteSettings];
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
