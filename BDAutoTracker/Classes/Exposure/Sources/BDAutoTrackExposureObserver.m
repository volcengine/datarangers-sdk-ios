//
//  BDAutoTrackExposureObserver.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackExposureObserver.h"
#import "UIView+BDAutoTrackExposure.h"
#import "BDAutoTrackExposureManager.h"
#import "RangersLog.h"

@implementation BDAutoTrackExposureObserver {
    
    BOOL _applicationActive;
    CFTimeInterval _latestTime;
    CFRunLoopObserverRef observer;
}
 


+ (instancetype)sharedObserver
{
    static BDAutoTrackExposureObserver *observer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [BDAutoTrackExposureObserver new];
    });
    return observer;
}

- (instancetype)init
{
    if(self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)start
{
    dispatch_block_t block = ^{
        
        static CFRunLoopObserverRef observer;

        if (observer) {
            return;
        }

        observer = CFRunLoopObserverCreateWithHandler(
                    NULL,
                    (kCFRunLoopBeforeWaiting| kCFRunLoopExit),
                    YES,
                    INT_MAX - 1,
                    ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                        [self maybeDetectVisbile];
                    });

        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
        CFRelease(observer);
        
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


#pragma mark - lifecycle
- (void)applicationDidBecomeActive
{
    _applicationActive = YES;
}

- (void)applicationWillResignActive
{
    _applicationActive = NO;
}

#pragma mark - start

- (void)maybeDetectVisbile
{
    
    if (!_applicationActive) {
        return;
    }
    CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
    if (current - _latestTime < 0.1f) {
        return;
    }
    @try {
        [self exposureDetect];
        _latestTime = CFAbsoluteTimeGetCurrent();
    } @finally {
    }

}

- (void)exposureDetect
{
    
    [[[BDAutoTrackExposureManager sharedInstance] observedViews] enumerateObjectsUsingBlock:^(UIView*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.window) {
            [obj bdexposure_markInvisible];
        }
        [obj bdexposure_markIfTrackable];
    }];
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        [window bdexposure_detectVisible:window.frame];
    }
}


@end
