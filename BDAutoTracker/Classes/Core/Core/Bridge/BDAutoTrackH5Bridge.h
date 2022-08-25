//
//  BDAutoTrackH5Bridge.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackH5Bridge : NSObject

+ (instancetype)sharedInstance;

- (void)swizzleWKWebViewMethodForJSBridge;

- (void)injectAppLogBridgeToWebView:(WKWebView *)webview;

@end

NS_ASSUME_NONNULL_END
