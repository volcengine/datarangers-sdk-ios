//
//  BDAutoTrackScreenOrientation.h
//  RangersAppLog
//
//  Created by bytedance on 2022/4/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>


/// 采集屏幕方向
@interface BDAutoTrackDeviceOrientation : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSString *deviceOrientation;

+ (instancetype)shared;

- (void)updateInterval: (NSTimeInterval)interval;

- (void)startDeviceMotion;

- (void)pauseDeviceMotion;

- (void)resumeDeviceMotion;

- (void)stopDeviceMotion;

@end

