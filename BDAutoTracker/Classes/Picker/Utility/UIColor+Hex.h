//
//  UIColor+Hex.h
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hex)

+ (instancetype)bd_colorWithRGB:(UInt32)hex;
+ (instancetype)bd_colorWithRGB:(UInt32)hex alpha:(CGFloat)alpha;
+ (instancetype)bd_colorWithRGBA:(UInt32)hex;

- (UIImage *)bp_imageWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
