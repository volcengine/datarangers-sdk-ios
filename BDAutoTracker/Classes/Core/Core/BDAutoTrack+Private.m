//
//  BDAutoTrack+Private.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

#import "BDAutoTrackServiceCenter.h"
#import "RangersLog.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"

#import "BDAutoTrackDataCenter.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackBatchTimer.h"

#if __has_include("BDAutoTrack+UITracker.h")
#import "BDAutoTrack+UITracker.h"
#endif
@implementation BDAutoTrack (Private)

@dynamic dataCenter;
@dynamic showDebugLog;
@dynamic gameModeEnable;
@dynamic serialQueue;
@dynamic alinkActivityContinuation;
@dynamic profileReporter;

+ (NSArray<BDAutoTrack *> *)allTrackers {
    return [[BDAutoTrackServiceCenter defaultCenter] servicesForName:BDAutoTrackServiceNameTracker];
}

+ (void)trackUIEventWithData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }

    NSString *event = [data objectForKey:@"event"];
    if (![NSJSONSerialization isValidJSONObject:data]) {
        RL_WARN(BDAutoTrack.appID, @"[AutoTracker] Event:%@ termimate due to INVALID PARAMETERS.", event);
        return;
    }
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        NSString *appID = track.appID;
        // 全埋点开关，有远端配置和本地代码的配置，两端都开启则开启，有一端关闭则关闭
        bool autoTrackEnabled = bd_remoteSettingsForAppID(appID).autoTrackEnabled && bd_settingsServiceForAppID(appID).autoTrackEnabled;
        
        //判断是否 Igore
        BOOL ignored = NO;
        if ([event isEqualToString:@"bav2b_page"]
            && [track respondsToSelector:@selector(isPageIgnored:)]) {
            NSString *className = [data objectForKey:@"page_key"];
            ignored = [track performSelector:@selector(isPageIgnored:) withObject:className];
        } else if ([event isEqualToString:@"bav2b_click"]
                   && [track respondsToSelector:@selector(isClickIgnored:)]) {
            NSString *className = [data objectForKey:@"element_type"];
            ignored = [track performSelector:@selector(isClickIgnored:) withObject:className];
        }

        if (!autoTrackEnabled) {
            RL_WARN(track.appID, @"[AutoTracker] Event:%@ termimate due to AUTOTACKER DISABLED.",event);
            continue;
        }
        
        if (ignored) {
            RL_WARN(track.appID, @"[AutoTracker] Event:%@ termimate due to IGNORED.",event);
            continue;
        }
        [track.dataCenter trackUIEventWithData:data];
    }
}

+ (void)trackPageLeaveEventWithData:(NSDictionary *)data {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(track.appID);
        if (settings.trackPageLeaveEnabled) {
            [track.dataCenter trackUserEventWithData:data];
        }
    }
}

+ (void)trackLaunchEventWithData:(NSMutableDictionary *)data {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        [track.dataCenter trackLaunchEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
    }
}

+ (void)trackTerminateEventWithData:(NSMutableDictionary *)data {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        [track.dataCenter trackTerminateEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
    }
}

+ (void)trackPlaySessionEventWithData:(NSDictionary *)data {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (track.gameModeEnable) {
            [track.dataCenter trackUserEventWithData:data];
        }
    }
}

- (void)setAppTouchPoint:(NSString *)appTouchPoint {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        [bd_settingsServiceForAppID(appID) saveAppTouchPoint:[appTouchPoint mutableCopy]];
    });
}

/// caller: Profile上报、Tracer上报
/// 若上次上报时间在flushTimeInterval内，立即发起一次Batch上报。
/// 传入timeInterval=0，可实现立即上报.
/// @param flushTimeInterval Flush上报的最小间隔，整数。单位：秒。
- (void)flushWithTimeInterval:(NSInteger)flushTimeInterval {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
        [service sendTrackDataFrom:BDAutoTrackTriggerSourceManually flushTimeInterval:flushTimeInterval];
    });
}


@end
