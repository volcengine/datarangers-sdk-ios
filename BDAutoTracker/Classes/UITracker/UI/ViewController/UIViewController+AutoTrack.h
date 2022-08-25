//
//  UIViewController+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

// hook UIViewcontroller 生命周期的方法


NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (AutoTrack)

+ (UIViewController *)bd_topViewController;

- (UIViewController *)bd_topViewController:(BOOL)showPresented;

- (NSString *)bd_pageTrackTitle;

- (NSMutableDictionary *)bd_pageTrackInfo;

- (NSMutableDictionary *)bd_referPageTrackInfo;

@end

NS_ASSUME_NONNULL_END
