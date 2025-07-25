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
#import "BDAutoTrackMainBundle.h"

#if __has_include("BDAutoTrack+UITracker.h")
#import "BDAutoTrack+UITracker.h"
#endif

#import "NSDictionary+VETyped.h"

@implementation BDAutoTrack (Private)

@dynamic dataCenter;
@dynamic showDebugLog;
@dynamic serialQueue;
@dynamic alinkActivityContinuation;
@dynamic profileReporter;

+ (NSArray<BDAutoTrack *> *)allTrackers {
    return [[BDAutoTrackServiceCenter defaultCenter] servicesForName:BDAutoTrackServiceNameTracker];
}

+ (BDAutoTrack *)trackerWithAppId:(NSString *)appID {
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if ([track isKindOfClass:[BDAutoTrack class]] && track.appID == appID) {
            continue;
        }
    }
    return nil;
}

+ (void)trackUIEventWithData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
    if ([className hasPrefix:@"BDAutoTrack"]) {
        return;
    }

    NSString *event = [data objectForKey:@"event"];
    if (![NSJSONSerialization isValidJSONObject:data]) {
        
        RL_WARN(BDAutoTrack.sharedTrack,@"AutoTrack", @"Event:%@ termimate due to INVALID PARAMETERS.", event);
        return;
    }
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        bool autoTrackEnabled = track.remoteConfig.autoTrackEnabled && track.localConfig.autoTrackEnabled;
        if (!autoTrackEnabled) {
            RL_WARN(track,@"AutoTrack", @"Event:%@ termimate due to AUTOTACKER DISABLED", event);
            continue;
        }
        
        BDAutoTrackLocalConfigService *settings = track.localConfig;
        BOOL ignored = NO;
        if ([event isEqualToString:@"bav2b_page"]) {
            if (!settings.trackPageEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isPageIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
                ignored = [track performSelector:@selector(isPageIgnored:) withObject:className];
            }
        } else if ([event isEqualToString:@"bav2b_click"]) {
            if (!settings.trackPageClickEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isClickIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"element_type"];
                ignored = [track performSelector:@selector(isClickIgnored:) withObject:className];
            }
        } else if ([event isEqualToString:@"$bav2b_page_leave"]) {
            if (!settings.trackPageLeaveEnabled) {
                continue;
            }
            
            if ([track respondsToSelector:@selector(isPageIgnored:)]) {
                NSString *className = [[data objectForKey:@"params"] objectForKey:@"page_key"];
                ignored = [track performSelector:@selector(isPageIgnored:) withObject:className];
            }
        }

        if (ignored) {
            RL_WARN(track, @"AutoTrack", @"Event:%@ termimate due to IGNORED.",event);
            continue;
        }
        
        if (track.config.rollback) {
            [track.dataCenter trackUIEventWithData:data];
        } else {
            [track.eventGenerator trackEventType:BDAutoTrackTableUIEvent eventBody:data options:nil];
        }
       
    }
}

+ (void)trackLaunchEventWithData:(NSMutableDictionary *)data {
    if (bd_is_extension()) {
        return;
    }
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (!track.config.launchTerminateEnable) {
            continue;
        }
        if (track.config.rollback) {
            [track.dataCenter trackLaunchEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
        } else {
            [track.eventGenerator trackLaunch:data];
        }
        
        if([data vetyped_boolForKey:kBDAutoTrackIsBackground]) {
            bool resumeFromBackground = [data vetyped_boolForKey:kBDAutoTrackResumeFromBackground];
            if (track.config.rollback) {
                NSDictionary *trackData = @{kBDAutoTrackEventType:@"$app_launch_passively",
                                            kBDAutoTrackEventData:@{kBDAutoTrackResumeFromBackground: @(resumeFromBackground)}};
                [track.dataCenter trackUserEventWithData:trackData];
            } else {
                [track.eventGenerator trackEvent:@"$app_launch_passively" parameter:@{kBDAutoTrackResumeFromBackground: @(resumeFromBackground)} options:nil];
            }
        }
    }
}

+ (void)trackTerminateEventWithData:(NSMutableDictionary *)data {
    if (bd_is_extension()) {
        return;
    }
    
    NSArray<BDAutoTrack *> *allTracker = [self allTrackers];
    for (BDAutoTrack *track in allTracker) {
        if (![track isKindOfClass:[BDAutoTrack class]]) {
            continue;
        }
        if (!track.config.launchTerminateEnable) {
            continue;
        }
        if (track.config.rollback) {
            [track.dataCenter trackTerminateEventWithData:[[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]];
        } else {
            [track.eventGenerator trackTerminate:data];
        }
    }
}

- (void)setAppTouchPoint:(NSString *)appTouchPoint {
    dispatch_async(self.serialQueue, ^{
        [self.localConfig saveAppTouchPoint:[appTouchPoint copy]];
    });
}

- (void)flushWithTimeInterval:(NSInteger)flushTimeInterval {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
        [service sendTrackDataFrom:BDAutoTrackTriggerSourceManually flushTimeInterval:flushTimeInterval];
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@-%@", self.config.appID, self.config.appName];
}


@end
