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

/// 触发源
typedef NS_ENUM(NSInteger, BDAutoTrackTriggerSource) {
    /// app启动触发
    BDAutoTrackTriggerSourceInitApp = 0x01,
    /// 定时器触发
    BDAutoTrackTriggerSourceTimer,
    /// 切到前台触发
    BDAutoTrackTriggerSourceEnterForground,
    /// 进入后台触发
    BDAutoTrackTriggerSourceEnterBackground,
    /// UUID 变化触发
    BDAutoTrackTriggerSourceUUIDChanged,
    /// 主动触发（通过BDAutoTrack.flush）
    BDAutoTrackTriggerSourceManually,
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
