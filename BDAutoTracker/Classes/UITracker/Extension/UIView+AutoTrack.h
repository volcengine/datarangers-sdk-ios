//
//  UIView+Controller.h
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

// UIView 所在 controller 相关的信息

NS_ASSUME_NONNULL_BEGIN

@interface UIView (AutoTrack)

- (nullable UIViewController *)bd_controller;
- (nullable NSString *)bd_elementContent;
- (NSMutableDictionary *)bd_trackInfo;
- (NSArray<NSString *> *)bd_trackTitles;

- (NSMutableArray<NSIndexPath *> *)bd_indexPath;
- (NSArray<NSIndexPath *> *)bd_positions;

- (BOOL)bd_isWebViewComponent;

@end

NS_ASSUME_NONNULL_END
