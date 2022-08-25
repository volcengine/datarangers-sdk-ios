//
//  TTTrackerGCDTimer.m
//  Pods
//
//  Created by fengyadong on 2017/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackTimer : NSObject

+ (instancetype)sharedInstance;

/**
 启动一个timer，默认精度为1毫秒
 
 @param timerName       timer的名称，作为唯一标识。
 @param interval        执行的时间间隔。单位：秒。类型：double。
 @param queue           timer将被放入的队列，也就是最终action执行的队列。传入nil将自动放到一个子线程队列中。
 @param repeats         timer是否循环调用。
 @param action          时间间隔到点时执行的block。
 */
- (void)scheduledDispatchTimerWithName:(nullable NSString *)timerName
                          timeInterval:(NSTimeInterval)interval
                                 queue:(nullable dispatch_queue_t)queue
                               repeats:(BOOL)repeats
                                action:(nullable dispatch_block_t)action;

/**
 撤销某个timer。
 
 @param timerName timer的名称，作为唯一标识。
 */
- (void)cancelTimerWithName:(NSString *)timerName;

@end

NS_ASSUME_NONNULL_END
