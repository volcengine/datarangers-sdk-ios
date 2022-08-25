//
//  BDAutoTrackPageLeave.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDurationEvent.h"
#import "BDAutoTrackUtility.h"
#import "RangersLog.h"
#import "BDUIAutoTracker.h"
#import "BDTrackConstants.h"
#import "BDAutoTrackPageLeave.h"
#import "UIViewController+AutoTrack.h"


@interface BDAutoTrackPageLeave()

@property (nonatomic, strong) BDAutoTrackDurationEvent *currentEvent;
@property (nonatomic, strong) NSMutableDictionary *eventDict;

@end



@implementation BDAutoTrackPageLeave

#pragma mark - init

+ (instancetype)shared {
    static BDAutoTrackPageLeave *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    
    self.enabled = YES;
    self.eventDict = [NSMutableDictionary dictionary];
    
    [self bindevents];

    return self;
}


#pragma mark - events

- (void)bindevents {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)onDidEnterBackground {
    if (self.enabled && self.currentEvent != nil) {
        NSNumber * nowTimeMS = bd_milloSecondsInterval();
        [self.currentEvent pause:nowTimeMS];
    }
}

- (void)onWillEnterForeground {
    if (self.enabled && self.currentEvent != nil) {
        NSNumber * nowTimeMS = bd_milloSecondsInterval();
        [self.currentEvent resume:nowTimeMS];
    }
}


#pragma mark - implementations

- (void)updateEnabled:(BOOL)enabled {
    self.enabled = enabled;
}

- (void)enterPage:(UIViewController *)vc {
    if (!self.enabled) {
        return;
    }
    
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    NSString * eventName = [self get_key_by_vc:vc];
    self.currentEvent = [BDAutoTrackDurationEvent createByEventName:eventName];
    [self.currentEvent start:nowTimeMS];
    [self.eventDict setValue:self.currentEvent forKey:eventName];
}

- (void)leavePage:(UIViewController *)vc {
    if (!self.enabled) {
        return;
    }
    
    BDAutoTrackDurationEvent *durationEvent = [self get_event_by_controller:vc];
    if (durationEvent == nil || durationEvent.state == BDAutoTrackDurationEventStop) {
        RL_WARN(@"", @"%@ track leavePage failed: should call enterPage first", durationEvent.eventName);
        return;
    }

    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    [durationEvent stop:nowTimeMS];
    NSDictionary *params = @{
        kBDAutoTrackEventPageDuration:[NSNumber numberWithLong:durationEvent.duration]
    };
    bd_ui_trackPageLeaveEvent(vc, params);

    NSString *key = [self get_key_by_vc:vc];
    [self.eventDict setValue:nil forKey:key];
}


#pragma mark - private functions

- (BDAutoTrackDurationEvent *)get_event_by_controller:(UIViewController *)vc {
    NSString *key = [self get_key_by_vc:vc];
    return self.eventDict[key];
}

- (NSString *)get_key_by_vc:(UIViewController *)vc {
    return [NSString stringWithFormat:@"bdautotrack_leave_page_event_%lu", vc.hash];
}


@end
