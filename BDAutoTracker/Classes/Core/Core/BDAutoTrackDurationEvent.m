//
//  BDAutoTrackDurationEvent.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDurationEvent.h"
#import "RangersLog.h"


#pragma mark - BDAutoTrackDurationEvent

@interface BDAutoTrackDurationEvent()

@end

@implementation BDAutoTrackDurationEvent

#pragma mark - BDAutoTrackDurationEvent init

+ (instancetype)createByEventName:(NSString *)eventName {
    BDAutoTrackDurationEvent *instance = [self new];
    [instance initWithEventName:eventName];
    return instance;
}

- (void)dealloc {}

- (instancetype)init {
    self = [super init];
    
    self.appId = @"";
    self.duration = 0;
    self.state = BDAutoTrackDurationEventInit;
    self.startTimeMS = 0;
    self.lastPauseTimeMS = 0;
    self.lastResumeTimeMS = 0;
    self.stopTimeMS = 0;
    
    return self;
}

- (void)initWithEventName:(NSString *)eventName {
    self.eventName = eventName;
}


#pragma mark - BDAutoTrackDurationEvent implementations

- (void)updateAppId:(NSString *)appId {
    self.appId = appId;
}

- (void)start:(NSNumber *)startTimeMS {
    if (self.state == BDAutoTrackDurationEventStop) {
        RL_WARN(self.appId, @"%@ start failed: already stoped!", self.eventName);
        return;
    }
    if (self.state != BDAutoTrackDurationEventInit) {
        RL_WARN(self.appId, @"%@ start failed: already started!", self.eventName);
        return;
    }
    
    self.startTimeMS = startTimeMS;
    self.state = BDAutoTrackDurationEventStart;
}

- (void)pause:(NSNumber *)pauseTimeMS {
    if (self.state == BDAutoTrackDurationEventInit) {
        RL_WARN(self.appId, @"%@ pause failed: did not start yet!", self.eventName);
        return;
    }
    if (self.state == BDAutoTrackDurationEventPause) {
        RL_WARN(self.appId, @"%@ pause failed: already paused!", self.eventName);
        return;
    }
    if (self.state == BDAutoTrackDurationEventStop) {
        RL_WARN(self.appId, @"%@ pause failed: already stoped!", self.eventName);
        return;
    }
    
    if (self.state == BDAutoTrackDurationEventStart) {
        self.duration += [pauseTimeMS longValue] - [self.startTimeMS longValue];
    } else if (self.state == BDAutoTrackDurationEventResume) {
        self.duration += [pauseTimeMS longValue] - [self.lastResumeTimeMS longValue];
    }
    self.lastPauseTimeMS = pauseTimeMS;
    self.state = BDAutoTrackDurationEventPause;
}

- (void)resume:(NSNumber *)resumeTimeMS {
    if (self.state != BDAutoTrackDurationEventPause) {
        RL_WARN(self.appId, @"%@ resume failed: did not pause yet!", self.eventName);
        return;
    }
    
    self.lastResumeTimeMS = resumeTimeMS;
    self.state = BDAutoTrackDurationEventResume;
}

- (void)stop:(NSNumber *)stopTimeMS {
    if (self.state == BDAutoTrackDurationEventInit) {
        RL_WARN(self.appId, @"%@ stop failed: did not start yet!", self.eventName);
        return;
    }
    if (self.state == BDAutoTrackDurationEventStop) {
        RL_WARN(self.appId, @"%@ stop failed: already stoped!", self.eventName);
        return;
    }
    
    if (self.state == BDAutoTrackDurationEventStart) {
        self.duration += [stopTimeMS longValue] - [self.startTimeMS longValue];
    } else if (self.state == BDAutoTrackDurationEventResume) {
        self.duration += [stopTimeMS longValue] - [self.lastResumeTimeMS longValue];
    } else if (self.state == BDAutoTrackDurationEventPause) {
        // do nothing
    }
    self.stopTimeMS = stopTimeMS;
    self.state = BDAutoTrackDurationEventStop;
}

@end



#pragma mark - BDAutoTrackDurationEventManager

@interface BDAutoTrackDurationEventManager()

@property (nonatomic, strong) NSMutableDictionary * eventDict;

@end

@implementation BDAutoTrackDurationEventManager

#pragma mark - BDAutoTrackDurationEventManager init

+ (instancetype)createByAppId:(NSString *)appId {
    BDAutoTrackDurationEventManager *instance = [self new];
    [instance initWithAppId:appId];
    return instance;
}

- (void)dealloc {}

- (instancetype)init {
    self = [super init];
    
    self.eventDict = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)initWithAppId:(NSString *)appId {
    self.appId = appId;
}


#pragma mark - BDAutoTrackDurationEvent implementations

- (void)startDurationEvent:(NSString *)eventName startTimeMS:(NSNumber *) startTimeMS {
    BDAutoTrackDurationEvent *durationEvent = [self getDurationEvent:eventName];
    if (durationEvent != nil && durationEvent.state != BDAutoTrackDurationEventStop) {
        RL_WARN(self.appId, @"startDurationEvent failed: %@ already exist!", eventName);
        return;
    }
    
    durationEvent = [BDAutoTrackDurationEvent createByEventName:eventName];
    [durationEvent updateAppId:self.appId];
    [durationEvent start:startTimeMS];
    [self.eventDict setValue:durationEvent forKey:eventName];
}

- (void)pauseDurationEvent:(NSString *)eventName pauseTimeMS:(NSNumber *) pauseTimeMS {
    BDAutoTrackDurationEvent *durationEvent = [self getDurationEvent:eventName];
    if (durationEvent == nil) {
        RL_WARN(self.appId, @"pauseDurationEvent failed: %@ not exist!", eventName);
        return;
    }
    
    [durationEvent pause:pauseTimeMS];
}

- (void)resumeDurationEvent:(NSString *)eventName resumeTimeMS:(NSNumber *) resumeTimeMS {
    BDAutoTrackDurationEvent *durationEvent = [self getDurationEvent:eventName];
    if (durationEvent == nil) {
        RL_WARN(self.appId, @"resumeDurationEvent failed: %@ not exist!", eventName);
        return;
    }
    
    [durationEvent resume:resumeTimeMS];
}

- (BDAutoTrackDurationEvent *)stopDurationEvent:(NSString *)eventName stopTimeMS:(NSNumber *) stopTimeMS {
    BDAutoTrackDurationEvent *durationEvent = [self getDurationEvent:eventName];
    if (durationEvent == nil) {
        RL_WARN(self.appId, @"stopDurationEvent failed: %@ not exist!", eventName);
        return nil;
    }
    
    [durationEvent stop:stopTimeMS];
    [self.eventDict setValue:nil forKey:eventName];
    return durationEvent;
}


#pragma mark - BDAutoTrackDurationEvent private functions

- (BDAutoTrackDurationEvent *)getDurationEvent:(NSString *)eventName {
    if ([self.eventDict[eventName] isKindOfClass:[BDAutoTrackDurationEvent class]]) {
        return self.eventDict[eventName];
    }
    return nil;
}

@end
