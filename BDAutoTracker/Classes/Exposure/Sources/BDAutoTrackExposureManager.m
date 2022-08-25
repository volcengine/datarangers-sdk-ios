//
//  BDAutoTrackExposureManager.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackExposureManager.h"
#import "RangersLog.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackExposure.h"
#import "BDTrackerObjectBindContext.h"
#import <QuartzCore/QuartzCore.h>
#import "BDAutoTrackExposureObserver.h"

#import "UIView+BDAutoTrackExposure.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackExposurePrivate.h"


@implementation BDAutoTrackExposureManager {
    
    NSHashTable * viewStore;
    
    BOOL exposureObserved;;
}

+ (instancetype)sharedInstance
{
    static BDAutoTrackExposureManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [BDAutoTrackExposureManager new];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        viewStore = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:50];
    }
    return self;
}

- (NSArray *)observedViews
{
    return viewStore.allObjects;
}

- (void)observe:(id)view
           with:(BDViewExposureData *)exp
     forTracker:(BDAutoTrack *)tracker;
{
    if (!view) { return; }
    if (!tracker) { return; }
    if (!tracker.config.exposureEnabled) {
        return;
    }
    
    if (exp.properties && ![NSJSONSerialization isValidJSONObject:exp.properties]) {
        RL_WARN([tracker appID], @"[Exposure] invalid properties when view is settings observable.");
        exp.properties = @{@"$error_message":@"invalid properties"};
    }
    
    dispatch_block_t block = ^{
        
        [view bdexposure_add:tracker with:exp];
        if (![self->viewStore containsObject:view]) {
            [self->viewStore addObject:view];
        }

    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)remove:(id)view
    forTracker:(BDAutoTrack *)tracker
{
    if (!view) {
        return;
    }
    if (!tracker) {
        return;
    }
    dispatch_block_t block = ^{
        
        [view bdexposure_clear:tracker];
        [self->viewStore removeObject:view];
        
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
}


- (void)startWithTracker:(BDAutoTrack *)tracker
{
    BDAutoTrackConfig *config = tracker.config;
    if (!config.exposureEnabled) {
        return;
    }
    
    if (config.exposureConfig.visualDiagnosisEnabled) {
        self.debugON = YES;
    }
    if (exposureObserved) {
        return;
    }
    [[BDAutoTrackExposureObserver sharedObserver] start];
    exposureObserved = YES;
}


@end
