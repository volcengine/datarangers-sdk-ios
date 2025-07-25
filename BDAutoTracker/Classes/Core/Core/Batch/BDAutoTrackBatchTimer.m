//
//  BDAutoTrackBatchTimer.m
//  RangersAppLog
//
//  Created by bob on 2019/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBatchTimer.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackTimer.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrack+Private.h"

static NSString *const kBDAutoTrackBatchRequestTimer    = @"kBDAutoTrackBatchRequestTimer";

@interface BDAutoTrackBatchTimer ()

@property (nonatomic, assign) BOOL didBecomeActive;
@property (nonatomic, copy) NSString *timerName;
#if TARGET_OS_IOS
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
#endif
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) BOOL isTerminating;

@end

@implementation BDAutoTrackBatchTimer

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = [appID mutableCopy] ?: @"";
        self.skipLaunch = bd_remoteSettingsForAppID(appID).skipLaunch;

        self.didBecomeActive = NO;
        self.batchInterval = 60;
        self.backgroundTimeout = 10.0;
        self.timerName = [kBDAutoTrackBatchRequestTimer stringByAppendingFormat:@"_%@",appID];
        self.isTerminating = NO;
        
#if TARGET_OS_IOS
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillTerminate)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
#elif TARGET_OS_OSX
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidBecomeActive)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:NSApplicationDidResignActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:NSApplicationWillBecomeActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillTerminate)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
#endif
        
        
        

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onRegisterSuccess:)
                                                     name:BDAutoTrackNotificationRegisterSuccess
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onActiveFinish:)
                                                     name:BDAutoTrackNotificationActiveSuccess
                                                   object:nil];
        
        
    }
    
    return self;
}

#pragma mark - Notification

- (void)onWillTerminate {
    self.isTerminating = YES;
}

- (void)onRegisterSuccess:(NSNotification *)not {
    NSString *appID = [not.userInfo vetyped_stringForKey:kBDAutoTrackNotificationAppID];
    if (![appID isEqualToString:self.appID]) {
        return;
    }
}

- (void)onDidBecomeActive {
    if (!self.didBecomeActive) {
        self.didBecomeActive = YES;
        [self startTimer];
        if (self.skipLaunch) {
            return;
        }
        BDAutoTrackWeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BDAutoTrackStrongSelf;
            if (self.isTerminating) {
                return;
            }
            if ([self.request respondsToSelector:@selector(sendTrackDataFrom:)]) {
                [self.request sendTrackDataFrom:BDAutoTrackTriggerSourceInitApp];
            }
        });
    }
}

- (void)onWillEnterForeground {
    if (self.skipLaunch) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.request respondsToSelector:@selector(sendTrackDataFrom:)]) {
            [self.request sendTrackDataFrom:BDAutoTrackTriggerSourceEnterForground];
        }
    });
}

- (void)onDidEnterBackground {
    
#if TARGET_OS_IOS
    
    BDAutoTrackWeakSelf;
    dispatch_block_t action = ^{
        BDAutoTrackStrongSelf;
        [self endBackgroundTask];
    };

    if (self.bgTask == UIBackgroundTaskInvalid) {
        self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:action];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.backgroundTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   action);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BDAutoTrackStrongSelf;
        if (self.isTerminating) {
            return;
        }
        if ([self.request respondsToSelector:@selector(sendTrackDataFrom:)]) {
            [self.request sendTrackDataFrom:BDAutoTrackTriggerSourceEnterBackground];
        }
    });
#else
    
    if ([self.request respondsToSelector:@selector(sendTrackDataFrom:)]) {
        [self.request sendTrackDataFrom:BDAutoTrackTriggerSourceEnterBackground];
    }
#endif
}


- (void)endBackgroundTask {
    
#if TARGET_OS_IOS
    BDAutoTrackWeakSelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        BDAutoTrackStrongSelf;
        if (UIBackgroundTaskInvalid != self.bgTask) {
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }
    });
#endif

}

#pragma mark - timer

- (void)updateTimerInterval:(NSTimeInterval)batchInterval {
    self.batchInterval = batchInterval;
    [self startTimer];
}

- (void)startTimer {
    BDAutoTrackWeakSelf;
    dispatch_block_t action = ^{
        BDAutoTrackStrongSelf;
        if (self.isTerminating) {
            return;
        }
        if ([self.request respondsToSelector:@selector(sendTrackDataFrom:)]) {
            [self.request sendTrackDataFrom:BDAutoTrackTriggerSourceTimer];
        }
    };
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:self.timerName
                                                         timeInterval:self.batchInterval
                                                                queue:dispatch_get_main_queue()
                                                              repeats:YES
                                                               action:action];
}

- (void)stopTimer {
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:self.timerName];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
}

@end
