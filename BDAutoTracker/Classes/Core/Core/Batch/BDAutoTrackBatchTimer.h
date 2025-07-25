//
//  BDAutoTrackBatchTimer.h
//  RangersAppLog
//
//  Created by bob on 2019/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackBatchService;

typedef NS_ENUM(NSInteger, BDAutoTrackTriggerSource) {
    BDAutoTrackTriggerSourceInitApp = 0x01,
    BDAutoTrackTriggerSourceTimer,
    BDAutoTrackTriggerSourceEnterForground,
    BDAutoTrackTriggerSourceEnterBackground,
    BDAutoTrackTriggerSourceManually,
    BDAutoTrackTriggerSourceRealtime,
    BDAutoTrackTriggerSourceEventCacheSize,
};

@interface BDAutoTrackBatchTimer : NSObject

@property (nonatomic, assign) BOOL skipLaunch;
@property (nonatomic, assign) CFTimeInterval batchInterval;
@property (nonatomic, assign) CFTimeInterval backgroundTimeout;
@property (nonatomic, weak) BDAutoTrackBatchService *request;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)endBackgroundTask;
- (void)updateTimerInterval:(NSTimeInterval)batchInterval;
- (void)stopTimer;

@end

NS_ASSUME_NONNULL_END
