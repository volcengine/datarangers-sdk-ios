//
//  WKWebView+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/4/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (AutoTrack)

/// SDK初始化时调用
+ (void)swizzleForH5AutoTrack;

@end

NS_ASSUME_NONNULL_END
