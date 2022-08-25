//
//  UIColor+Hex.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (instancetype)bd_colorWithRGB:(UInt32)hex {
    CGFloat r = ((hex & 0xFF0000) >> 16) /255.0;
    CGFloat g = ((hex & 0x00FF00) >> 8) /255.0;
    CGFloat b = ((hex & 0x0000FF) >> 0) /255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

+ (instancetype)bd_colorWithRGBA:(UInt32)hex {
    CGFloat r = ((hex & 0xFF000000) >> 24) /255.0;
    CGFloat g = ((hex & 0x00FF0000) >> 16) /255.0;
    CGFloat b = ((hex & 0x0000FF00) >> 8) /255.0;
    CGFloat a = ((hex & 0x000000FF) >> 0) /255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+ (instancetype)bd_colorWithRGB:(UInt32)hex alpha:(CGFloat)alpha {
    CGFloat r = ((hex & 0xFF0000) >> 16) /255.0;
    CGFloat g = ((hex & 0x00FF00) >> 8) /255.0;
    CGFloat b = ((hex & 0x0000FF) >> 0) /255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

- (UIImage *)bp_imageWithSize:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
