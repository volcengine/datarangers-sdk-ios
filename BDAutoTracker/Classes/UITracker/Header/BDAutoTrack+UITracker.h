//
//  BDAutoTrack+UITracker.h
//  RangersAppLog
//
//  Created by bytedance on 1/27/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDAutoTrack (UITracker)

- (void)ignoreAutoTrackPage:(NSArray<Class> *)controllerClasses;

- (void)ignoreAutoTrackClick:(NSArray<Class> *)viewClasses;

- (BOOL)trackPage:(id<BDAutoTrackable>)controller;

- (BOOL)trackPage:(id)controller withParameters:(nullable NSDictionary<NSString *,id> *)params;

- (BOOL)trackClick:(id<BDAutoTrackable>)view;

- (BOOL)trackClick:(id<BDAutoTrackable>)view withParameters:(nullable NSDictionary<NSString *,id> *)params;

- (BOOL)isPageIgnored:(id)controller;
- (BOOL)isClickIgnored:(id)view;

+ (BOOL)isPageIgnored:(id)controller;

- (nullable NSString *)lastPageKey;


@end

NS_ASSUME_NONNULL_END
