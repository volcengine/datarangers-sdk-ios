//
//  WKWebView+Picker.m
//  Applog
//
//  Created by bob on 2019/4/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "WKWebView+Picker.h"
#import <objc/runtime.h>
#import "BDPickerView.h"
#import "BDWebViewPickerJS.h"
#import "BDPickerConstants.h"
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackMacro.h"
#import "RangersAppLogConfig.h"

static NSString *const BDPickerMessageName    = @"window.TEAWebviewInfo();";

@interface BDWKWebViewPicker : NSObject

@property (nonatomic, strong) AppLogPickerView *pickerResult;

@end

@implementation BDWKWebViewPicker

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pickerStart)
                                                     name:kBDPickerStartNotification
                                                   object:nil];
    }

    return self;
}

- (void)pickerStart {
    self.pickerResult = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation WKWebView (Picker)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Init_Method_Imp = nil;
    dispatch_once(&onceToken, ^{
        original_Init_Method_Imp = bd_swizzle_instance_methodWithBlock(
           [self class],
           @selector(initWithFrame:configuration:),
           ^WKWebView * (WKWebView *_self,CGRect frame, WKWebViewConfiguration *configuration) {
            if (original_Init_Method_Imp) {
                WKWebView *webview = ((WKWebView * ( *)(id, SEL, CGRect, WKWebViewConfiguration *))original_Init_Method_Imp)(_self, @selector(initWithFrame:configuration:), frame, configuration);
                webview.bd_pickJSInjected = NO;
                
                configuration = configuration ?: [[WKWebViewConfiguration alloc] init];
                configuration.userContentController = configuration.userContentController ?: [[WKUserContentController alloc] init];
                
                // 如果已连接到服务器圈选，则注入生成DOM结构的JS代码
                if ([[RangersAppLogConfig sharedInstance] isSeversidePickerAvailable]) {
                    WKUserScript *script = [[WKUserScript alloc] initWithSource:bd_picker_pickerJS()
                                                                  injectionTime:(WKUserScriptInjectionTimeAtDocumentEnd)
                                                               forMainFrameOnly:NO];
                    [configuration.userContentController addUserScript:script];
                    webview.bd_pickJSInjected = YES;
                }

                return webview;
            }

            return nil;
        }); // bd_swizzle_instance_methodWithBlock
    }); // dispatch_once
}

- (void)setBd_PickerDecorator:(id)object {
    objc_setAssociatedObject(self, @selector(bd_PickerDecorator), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)bd_PickerDecorator {
    BDWKWebViewPicker *proxy = objc_getAssociatedObject(self, @selector(bd_PickerDecorator));
    if (!proxy) {
        proxy = [BDWKWebViewPicker new];
        [self setBd_PickerDecorator:proxy];
    }

    return proxy;
}

- (void)setBd_pickJSInjected:(BOOL)object {
    objc_setAssociatedObject(self, @selector(bd_pickJSInjected), @(object), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bd_pickJSInjected {
    return [objc_getAssociatedObject(self, @selector(bd_pickJSInjected)) boolValue];
}

- (AppLogPickerView *)bd_pickerView {
    BDWKWebViewPicker *proxy = [self bd_PickerDecorator];
    if (proxy.pickerResult) {
        return proxy.pickerResult;
    }
    if (!self.bd_pickJSInjected) {
        self.bd_pickJSInjected = YES;
        [self evaluateJavaScript:bd_picker_pickerJS() completionHandler:nil];
    }

    BDAutoTrackWeakSelf;
    [self evaluateJavaScript:BDPickerMessageName completionHandler:^(id data, NSError *error) {
        BDAutoTrackStrongSelf;
        AppLogPickerView *result = nil;
        if (data && !error) {
            if ([data isKindOfClass:[NSDictionary class]]) {
                result = [[AppLogPickerView alloc] initWithWebView:self data:data];
            } else if ([data isKindOfClass:[NSString class]]) {
                NSData *jsonData = [data dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError = nil;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:&jsonError];
                if (object && !jsonError) {
                    result = [[AppLogPickerView alloc] initWithWebView:self data:object];
                }
            }
        }

        proxy.pickerResult = result;
    }];

    return nil;
}

@end
