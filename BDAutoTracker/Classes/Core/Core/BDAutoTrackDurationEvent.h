//
//  BDAutoTrackDurationEvent.h
//  RangersAppLog
//
//  Created by bytedance on 2022/4/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>


#pragma mark - BDAutoTrackDurationEvent

enum BDAutoTrackDurationEventState {
    BDAutoTrackDurationEventInit,
    BDAutoTrackDurationEventStart,
    BDAutoTrackDurationEventPause,
    BDAutoTrackDurationEventResume,
    BDAutoTrackDurationEventStop,
};

@interface BDAutoTrackDurationEvent : NSObject

@property (nonatomic, strong) NSString * appId;
@property (nonatomic, strong) NSString * eventName;
@property (nonatomic, assign) long duration;
@property (nonatomic, assign) enum BDAutoTrackDurationEventState state;

@property (nonatomic, assign) NSNumber * startTimeMS;
@property (nonatomic, assign) NSNumber * lastPauseTimeMS;
@property (nonatomic, assign) NSNumber * lastResumeTimeMS;
@property (nonatomic, assign) NSNumber * stopTimeMS;


+ (instancetype)createByEventName:(NSString *)eventName;

- (void)updateAppId:(NSString *)appId;

- (void)start:(NSNumber *)startTimeMS;

- (void)pause:(NSNumber *)pauseTimeMS;

- (void)resume:(NSNumber *)resumeTimeMS;

- (void)stop:(NSNumber *)stopTimeMS;

@end



#pragma mark - BDAutoTrackDurationEventManager

@interface BDAutoTrackDurationEventManager : NSObject

@property (nonatomic, strong) NSString * appId;


+ (instancetype)createByAppId:(NSString *)appId;

- (void)startDurationEvent:(NSString *)eventName startTimeMS:(NSNumber *) startTimeMS;

- (void)pauseDurationEvent:(NSString *)eventName pauseTimeMS:(NSNumber *) pauseTimeMS;

- (void)resumeDurationEvent:(NSString *)eventName resumeTimeMS:(NSNumber *) resumeTimeMS;

- (BDAutoTrackDurationEvent *)stopDurationEvent:(NSString *)eventName stopTimeMS:(NSNumber *) stopTimeMS;

@end

