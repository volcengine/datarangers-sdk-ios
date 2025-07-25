//
//  BDAutoTrackSchemeHandler.m
//  RangersAppLog
//
//  Created by bob on 2019/9/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSchemeHandler.h"
#import "BDAutoTrackSchemeHandler+Internal.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackInternalHandler.h"
#import "RangersLog.h"
#import "BDAutoTrackUI.h"

static NSMutableDictionary * bd_picker_URLReportParameters(NSURL *URL) {
    if (![URL isKindOfClass:[NSURL class]]) {
        return nil;
    }

    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setValue:URL.scheme forKey:@"scheme"];
    [result setValue:URL.host forKey:@"host"];
    [result setValue:URL.path forKey:@"path"];
    [result setValue:bd_dictionaryFromQuery(URL.query) forKey:@"query"];

    return result;
}

@interface BDAutoTrackSchemeHandler ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDAutoTrackInternalHandler *> *internalHandlers;
@property (nonatomic, strong) NSMutableSet<id<BDAutoTrackSchemeHandler>> *handlers;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDAutoTrackSchemeHandler

+ (instancetype)sharedHandler {
    static BDAutoTrackSchemeHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [self new];
    });

    return handler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.handlers = [NSMutableSet new];
        self.internalHandlers = [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

- (BOOL)handleURL:(NSURL *)URL appID:(NSString *)appID scene:(id)scene {
    NSString *targetAppID = [appID copy];
    if ([targetAppID hasPrefix:@"rangers://"]) {
        @try {
            NSURL *aidUrl = [NSURL URLWithString:targetAppID];
            NSString *aidBase64 = [[aidUrl.path stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByRemovingPercentEncoding];
            NSString *aidMd5 = aidUrl.host;
            if (aidBase64.length > 0 && aidMd5.length > 0) {
                NSString *parserAid = ral_base64_string(aidBase64);
                if ([bd_calc_md5([parserAid UTF8String]) caseInsensitiveCompare:aidMd5] == NSOrderedSame) {
                    targetAppID = parserAid;
                }
            }
        } @catch (NSException *exception) {
        }
    }
    if (![URL isKindOfClass:NSURL.class] || URL.absoluteString.length < 1) {
        NSLog(@"[Rangers:%@][OPEN_URL] terminate due to invalid URL.",targetAppID);
        return NO;
    }
    NSURL *targetURL = [URL copy];
    if (![targetURL.scheme.lowercaseString hasPrefix:@"rangersapplog"]) {
        return NO;
    }
    
    if (![targetAppID isKindOfClass:[NSString class]] || targetAppID.length < 1) {
        NSLog(@"[Rangers:%@][OPEN_URL] terminate due to Invalid appId.", targetAppID);
        return NO;
    }
   
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:targetAppID];
    if (!tracker) {
        NSLog(@"[Rangers:%@][OPEN_URL] terminate due to Tracker instance has not finished initializing.", targetAppID);
        return NO;
    }
    RL_DEBUG(tracker,@"OPEN_URL", @"process start. (%@:%@)", targetAppID, targetURL.absoluteString);
    [tracker eventV3:@"bav_scheme" params:bd_picker_URLReportParameters(targetURL)];
    

    if ([self handleInternalURL:targetURL appID:targetAppID scene:scene]) {
        RL_INFO(targetAppID, @"OPEN_URL",@"sdk process successful. (%@)", targetURL.absoluteString);
        return YES;
    } else {
        RL_ERROR(targetAppID, @"OPEN_URL",@"sdk process failure. (%@)", targetURL.absoluteString);
    }

    BOOL handled = NO;
    BDSemaphoreLock(self.semaphore);
    RL_INFO(targetAppID, @"OPEN_URL",@"custom process start. (%@)", targetURL.absoluteString);
    for (id<BDAutoTrackSchemeHandler> handler in self.handlers) {
        
        if ([handler handleURL:targetURL appID:targetAppID scene:scene]) {
            RL_INFO(targetAppID, @"OPEN_URL",@"custom process successful. (%@)", targetURL.absoluteString);
            handled = YES;
            break;
        }
    }
    if (handled) {
        RL_INFO(targetAppID, @"OPEN_URL",@"custom process successful. (%@)", targetURL.absoluteString);
        return YES;
    } else {
        RL_ERROR(targetAppID, @"OPEN_URL",@"custom process failure. (%@)", targetURL.absoluteString);
    }
    BDSemaphoreUnlock(self.semaphore);
    return handled;
}

- (void)registerHandler:(id<BDAutoTrackSchemeHandler>)handler {
    if (!handler || ![handler respondsToSelector:@selector(handleURL:appID:scene:)]) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    [self.handlers addObject:handler];
    BDSemaphoreUnlock(self.semaphore);
}

- (void)unregisterHandler:(id<BDAutoTrackSchemeHandler>)handler {
    if (!handler) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    [self.handlers removeObject:handler];
    BDSemaphoreUnlock(self.semaphore);
}

@end
