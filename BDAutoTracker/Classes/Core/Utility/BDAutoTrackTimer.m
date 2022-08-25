//
//  TTTrackerGCDTimer.m
//  Pods
//
//  Created by fengyadong on 2017/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
//

#import "BDAutoTrackTimer.h"
#import <pthread/pthread.h>

@interface BDAutoTrackTimer() {
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) NSMutableDictionary *timerContainer;

@end

@implementation BDAutoTrackTimer

#pragma mark - Public Method

+ (BDAutoTrackTimer *)sharedInstance {
    static BDAutoTrackTimer *_gcdTimerManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^{
        _gcdTimerManager = [self new];
    });
    
    return _gcdTimerManager;
}

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _timerContainer = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)scheduledDispatchTimerWithName:(NSString *)timerName
                          timeInterval:(NSTimeInterval)interval
                                 queue:(dispatch_queue_t)queue
                               repeats:(BOOL)repeats
                                action:(dispatch_block_t)action {
    if (interval < 0.0001f) return;
    if (!action) return;
    if (!timerName) return;
    if (!queue) queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    pthread_mutex_lock(&_lock);
    dispatch_source_t timer = [self.timerContainer objectForKey:timerName];
    if (!timer) {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(timer);
        [self.timerContainer setValue:timer forKey:timerName];
    }
    pthread_mutex_unlock(&_lock);
    
    dispatch_time_t timerStartTime = dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC);
    uint64_t timerInterval = interval * NSEC_PER_SEC;
    uint64_t timerLeeway = NSEC_PER_MSEC; /* timer精度为1毫秒 */
    dispatch_source_set_timer(timer,
                              timerStartTime,
                              timerInterval,
                              timerLeeway);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        if (!repeats) {
            [weakSelf cancelTimerWithName:timerName];
        }

        if (action) {
            action();
        }
    });
}

- (void)cancelTimerWithName:(NSString *)timerName {
    pthread_mutex_lock(&_lock);
    dispatch_source_t timer = [self.timerContainer objectForKey:timerName];
    if (timer) {
        [self.timerContainer removeObjectForKey:timerName];
        dispatch_source_cancel(timer);
    }
    pthread_mutex_unlock(&_lock);
}

@end
