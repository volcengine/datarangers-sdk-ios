//
//  BDAutoTrackUISessionHandler.m
//  RangersAppLog
//
//  Created by bob on 2019/9/23.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackUISessionHandler.h"
#import "BDUIAutoTracker.h"

__attribute__((constructor)) void bdauto_track_ui_session(void) {
    [BDAutoTrackUISessionHandler sharedHandler];
}

@interface BDAutoTrackUISessionHandler ()

@property (nonatomic, assign) BOOL needTrackLauchPage;

@end

/// 单例，SDK启动时自动初始化
@implementation BDAutoTrackUISessionHandler

+ (instancetype)sharedHandler {
    static BDAutoTrackUISessionHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [self new];
    });

    return handler;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.needTrackLauchPage = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidBecomeActive) name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillResignActive) name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }

    return self;
}

- (void)onDidBecomeActive {
    if (self.needTrackLauchPage) {
        bd_ui_trackLauchPage();
        self.needTrackLauchPage = NO;
    }
}

- (void)onWillResignActive {
    bd_ui_storeTerminatePage();
}

- (void)onWillEnterForeground {
    self.needTrackLauchPage = YES;
}

- (void)onDidEnterBackground {
    bd_ui_trackTerminatePage();
}

@end
