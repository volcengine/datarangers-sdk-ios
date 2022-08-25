//
//  WKWebView+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/4/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "WKWebView+AutoTrack.h"
#import <objc/runtime.h>
#import "BDWKScriptMessageHandler.h"
#import "BDAutoTrackWebViewTrackJS.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"

static NSString *const BDAutoTrackMessageName    = @"TEANativeReport";

@implementation WKWebView (AutoTrack)

+ (void)swizzleForH5AutoTrack {
    static dispatch_once_t onceToken;
    static IMP original_Init_Method_Imp = nil;
    dispatch_once(&onceToken, ^{

        original_Init_Method_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(initWithFrame:configuration:), ^WKWebView * (WKWebView *_self,CGRect frame, WKWebViewConfiguration *configuration){
            if (original_Init_Method_Imp) {
                if (!configuration) {
                    configuration = [[WKWebViewConfiguration alloc] init];
                }
                WKUserContentController *userContent = configuration.userContentController;
                if (!userContent) {
                    userContent = [[WKUserContentController alloc] init];
                }
                BDWKScriptMessageHandler *handler = [BDWKScriptMessageHandler handlerWithMessageName:BDAutoTrackMessageName handler:^(WKScriptMessage *message) {
                    if (message.body) {
                        bd_ui_trackWebEvent(message.body);
                    }
                }];
                [userContent removeScriptMessageHandlerForName:BDAutoTrackMessageName];
                [userContent addScriptMessageHandler:handler name:BDAutoTrackMessageName];

                configuration.userContentController = userContent;
                WKUserScript *script = [[WKUserScript alloc] initWithSource:bd_ui_trackJS()
                                                              injectionTime:(WKUserScriptInjectionTimeAtDocumentEnd)
                                                           forMainFrameOnly:NO];
                [userContent addUserScript:script];
                return ((WKWebView * ( *)(id, SEL, CGRect, WKWebViewConfiguration *))original_Init_Method_Imp)(_self, @selector(initWithFrame:configuration:), frame, configuration);
            }

            return nil;
        });
    });
}

@end
