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
    
    
    if ([URL.absoluteString length] == 0) {
        RL_WARN(appID, @"[URL_Handler] terminate due to EMPTY URL. (%@)", appID);
        return NO;
    }
    RL_DEBUG(appID, @"[URL_Handler] process start. (%@)", URL.absoluteString);
    
    if (![appID isKindOfClass:[NSString class]] || appID.length < 1) {
        RL_WARN(appID, @"[URL_Handler] terminate due to INVALID APPID. (%@)", appID);
        return NO;
    }

    BDAutoTrack *track = [BDAutoTrack trackWithAppID:appID];
    if ([track isKindOfClass:[BDAutoTrack class]]) {
        [track eventV3:@"bav_scheme" params:bd_picker_URLReportParameters(URL)];
    } else {
        RL_WARN(appID, @"[URL_Handler] terminate due to NO TRACKER FOUND. (%@)", appID);
        return NO;
    }
    
    if ([self handleInternalURL:URL appID:appID scene:scene]) {
        RL_DEBUG(appID, @"[URL_Handler] process successful. (%@)", URL.absoluteString);
        return YES;
    } else {
        RL_ERROR(appID, @"[URL_Handler] handleInternalURL:appID:scene: process failure. (%@)", URL.absoluteString);
    }

    BOOL handled = NO;
    BDSemaphoreLock(self.semaphore);
    for (id<BDAutoTrackSchemeHandler> handler in self.handlers) {
        
        RL_DEBUG(appID, @"[URL_Handler] BDAutoTrackSchemeHandler trying . (%@)", handler);
        if ([handler handleURL:URL appID:appID scene:scene]) {
            RL_DEBUG(appID, @"[URL_Handler] BDAutoTrackSchemeHandler process successful . (%@)", handler);
            handled = YES;
            break;
        } else {
            RL_DEBUG(appID, @"[URL_Handler] BDAutoTrackSchemeHandler process failure . (%@)", handler);
        }
    }
    BDSemaphoreUnlock(self.semaphore);

    RL_DEBUG(appID, @"[URL_Handler] process failure. (%@)", URL.absoluteString);
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
