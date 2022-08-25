//
//  BDAutoTrackPageLeave.h
//  RangersAppLog
//
//  Created by bytedance on 2022/4/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

@interface BDAutoTrackPageLeave : NSObject

@property (nonatomic, assign) BOOL enabled;


+ (instancetype)shared;

- (void)updateEnabled:(BOOL)enabled;

- (void)enterPage:(UIViewController *)vc;

- (void)leavePage:(UIViewController *)vc;


@end
