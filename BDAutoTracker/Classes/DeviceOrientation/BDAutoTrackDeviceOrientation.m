//
//  BDAutoTrackScreenOrientation.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "BDAutoTrackDeviceOrientation.h"

@interface BDAutoTrackDeviceOrientation()

@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, strong) CMMotionManager *cmmotionManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end


@implementation BDAutoTrackDeviceOrientation

+ (instancetype)shared {
    static BDAutoTrackDeviceOrientation *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)dealloc {
    [self stop];
    [self.operationQueue cancelAllOperations];
    [self.operationQueue waitUntilAllOperationsAreFinished];
    self.operationQueue = nil;
    self.cmmotionManager = nil;
}

- (instancetype)init {
    self = [super init];
    self.enabled = NO;
    self.interval = 0.5;
    self.deviceOrientation = @"";
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.name = @"com.rangersapplog.BDAutoTrackDeviceOrientation";
    
    self.cmmotionManager = [[CMMotionManager alloc] init];
    self.cmmotionManager.deviceMotionUpdateInterval = self.interval;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidEnterBackground)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    return self;
}


#pragma mark - app lifecycle

- (void)onWillEnterForeground {
    [self resumeDeviceMotion];
}

- (void)onDidEnterBackground {
    [self pauseDeviceMotion];
}


#pragma mark - key functions

- (void)start {
    if (self.cmmotionManager.isDeviceMotionAvailable && !self.cmmotionManager.isDeviceMotionActive) {
        [self.cmmotionManager startDeviceMotionUpdatesToQueue:self.operationQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            if (self == nil) {
                return;
            }
            
            double x = motion.gravity.x;
            double y = motion.gravity.y;
            self.deviceOrientation = (fabs(y) >= fabs(x)) ? @"portrait" : @"landscape";
        }];
    }
}

- (void)stop {
    if (self.cmmotionManager.isDeviceMotionActive) {
        [self.cmmotionManager stopDeviceMotionUpdates];
    }
}


#pragma mark - implementations

- (void)updateInterval: (NSTimeInterval)interval {
    self.interval = interval;
    self.cmmotionManager.deviceMotionUpdateInterval = self.interval;
}

- (void)startDeviceMotion {
    self.enabled = YES;
    [self start];
}

- (void)pauseDeviceMotion {
    [self stop];
}

- (void)resumeDeviceMotion {
    if (self.enabled) {
        [self start];
    }
}

- (void)stopDeviceMotion {
    self.enabled = NO;
    [self stop];
}


@end
