//
//  BDAutoTrackH5Bridge.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackH5Bridge.h"
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackScriptMessageHandler.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackServiceCenter.h"

@implementation BDAutoTrackH5Bridge

+ (instancetype)sharedInstance {
    static BDAutoTrackH5Bridge *bridge;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bridge = [[BDAutoTrackH5Bridge alloc] init];
    });
    return bridge;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // pass
    }
    return self;
}

- (void)swizzleWKWebViewMethodForJSBridge {
    static IMP orig_LoadRequest_IMP, orig_LoadHTMLString_IMP, orig_LoadFileURL_IMP, orig_LoadDataMIMEType_IMP;
    static dispatch_once_t onceTokenWebView;
    dispatch_once(&onceTokenWebView, ^{
        orig_LoadRequest_IMP = bd_swizzle_instance_methodWithBlock([WKWebView class], @selector(loadRequest:), ^ WKNavigation * (WKWebView *_self, NSURLRequest *request) {
            if (orig_LoadRequest_IMP) {
                WKNavigation *_ = ((WKNavigation * (*) (id, SEL, NSURLRequest *) )orig_LoadRequest_IMP)(_self, @selector(loadRequest:), request);
                [[BDAutoTrackH5Bridge sharedInstance] injectAppLogBridgeToWebView:_self];
                return _;
            }
            return nil;
        });
        
        // orig types @32@0:8@16@24
        orig_LoadHTMLString_IMP = bd_swizzle_instance_methodWithBlock([WKWebView class], @selector(loadHTMLString:baseURL:), ^ WKNavigation * (WKWebView *_self, NSString *string, NSURL *baseURL) {
            if (orig_LoadHTMLString_IMP) {
                WKNavigation *_ = ((WKNavigation * (*) (id, SEL, NSString *, NSURL *) )orig_LoadHTMLString_IMP)(_self, @selector(loadHTMLString:baseURL:), string, baseURL);
                [[BDAutoTrackH5Bridge sharedInstance] injectAppLogBridgeToWebView:_self];
                return _;
            }
            return nil;
        });
        
        if (@available(iOS 9.0, *)) {
            orig_LoadFileURL_IMP = bd_swizzle_instance_methodWithBlock([WKWebView class], @selector(loadFileURL:allowingReadAccessToURL:), ^ WKNavigation * (WKWebView *_self, NSURL *URL, NSURL *readAccessURL) {
                if (orig_LoadFileURL_IMP) {
                    WKNavigation *_ = ((WKNavigation * (*) (id, SEL, NSURL *, NSURL *) )orig_LoadFileURL_IMP)(_self, @selector(loadFileURL:allowingReadAccessToURL:), URL, readAccessURL);
                    [[BDAutoTrackH5Bridge sharedInstance] injectAppLogBridgeToWebView:_self];
                    return _;
                }
                return nil;
            });
            
            orig_LoadDataMIMEType_IMP = bd_swizzle_instance_methodWithBlock([WKWebView class], @selector(loadData:MIMEType:characterEncodingName:baseURL:), ^ WKNavigation * (WKWebView *_self, NSData *data, NSString *MIMEType, NSString *characterEncodingName, NSURL *baseURL) {
                if (orig_LoadDataMIMEType_IMP) {
                    WKNavigation *_ = ((WKNavigation * (*) (id, SEL, NSData *, NSString *, NSString *, NSURL *) )orig_LoadDataMIMEType_IMP)(_self, @selector(loadData:MIMEType:characterEncodingName:baseURL:), data, MIMEType, characterEncodingName, baseURL);
                    [[BDAutoTrackH5Bridge sharedInstance] injectAppLogBridgeToWebView:_self];
                    return _;
                }
                return nil;
            });
        }
    });
}

- (void)injectAppLogBridgeToWebView:(WKWebView *)webview {
    static WKUserScript *injectingScript;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *injectingJS = [self injectingJS];
        if (injectingJS.length) {
            injectingScript = [[WKUserScript alloc] initWithSource:injectingJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        }
    });
    
    BOOL shouldInjectScript = YES;
    if ([webview.URL.scheme isEqualToString:@"http"] || [webview.URL.scheme isEqualToString:@"https"]) {
        NSArray<BDAutoTrack *> *allTrackers = [[BDAutoTrackServiceCenter defaultCenter] servicesForName:BDAutoTrackServiceNameTracker];
        for (BDAutoTrack *track in allTrackers) {
            if (![track isKindOfClass:[BDAutoTrack class]]) {
                continue;
            }
            NSString *appID = track.appID;
            BDAutoTrackLocalConfigService *localSettings = bd_settingsServiceForAppID(appID);
            NSArray<NSString *> *allowedDomainPatterns = localSettings.H5BridgeAllowedDomainPatterns;
            BOOL allowAll = localSettings.H5BridgeDomainAllowAll;
            
            // 判断当前实例是否允许该域名注入bridge
            BOOL isAllowedDomain = NO;
            if (allowAll) {
                shouldInjectScript = YES;
                break;
            } else {
                NSString *host = webview.URL.host;
                for (NSString *allowedPattern in allowedDomainPatterns) {
                    isAllowedDomain = URLMatchPattern(host, allowedPattern);
                    if (isAllowedDomain) break;
                }
                shouldInjectScript = isAllowedDomain;
                if (shouldInjectScript) {
                    break;
                }
            }
        }
    }
    
    if (shouldInjectScript && injectingScript) {
        WKUserContentController *ucc = webview.configuration.userContentController;
        NSArray<WKUserScript *> *userScripts = ucc.userScripts;
        BOOL hasInjected = NO;
        for (WKUserScript *us in userScripts) {
            if (us == injectingScript) {
                hasInjected = YES;
            }
        }
        
        if (!hasInjected) {
            /* 设置MessageHandler */
            [ucc removeScriptMessageHandlerForName:rangersapplog_script_message_handler_name];
            [ucc addScriptMessageHandler:[[BDAutoTrackScriptMessageHandler alloc] init] name:rangersapplog_script_message_handler_name];
            
            /* 注入UserScript */
            [ucc addUserScript:injectingScript];
        }
    }
}

- (NSString *)injectingJS {
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"RangersAppLog.bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithURL:bundleURL];
    NSString *jsFilePath = [resourceBundle pathForResource:@"h5bridge-wkwebview" ofType:@"js"];
    NSString *jsFileContent = [NSString stringWithContentsOfFile:jsFilePath encoding:NSUTF8StringEncoding error:nil];
    
    return jsFileContent;
}

@end
