//
//  TTTrackerGCDTimer.m
//  Pods
//
//  Created by fengyadong on 2017/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackTimer : NSObject

+ (instancetype)sharedInstance;

- (void)scheduledDispatchTimerWithName:(nullable NSString *)timerName
                          timeInterval:(NSTimeInterval)interval
                                 queue:(nullable dispatch_queue_t)queue
                               repeats:(BOOL)repeats
                                action:(nullable dispatch_block_t)action;

- (void)cancelTimerWithName:(NSString *)timerName;

@end

NS_ASSUME_NONNULL_END
