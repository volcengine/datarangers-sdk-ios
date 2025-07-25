//
//  BDAutoTrackSchemeHandler+Internal.m
//  RangersAppLog
//
//  Created by bob on 2020/5/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSchemeHandler+Internal.h"
#import "BDAutoTrackInternalHandler.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMacro.h"
#import "NSDictionary+VETyped.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackInternalHandler.h"

#import "RangersLog.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackUI.h"

static NSString * const BDPickerScheme = @"rangersapplog";
static NSString * const BDPickerSchemePath = @"picker";


@implementation BDAutoTrackSchemeHandler (Internal)

@dynamic semaphore;
@dynamic internalHandlers;

- (BOOL)handleInternalURL:(NSURL *)URL appID:(NSString *)appID scene:(id)scene {
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    if (!URL) {
        return NO;
    }
    NSString *host = URL.host;
    if (![host.lowercaseString isEqualToString:BDPickerScheme]) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to INVALID HOST. (%@)", host);
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to invalid host."];
        return NO;
    }
    NSString *path = URL.path;
    if (![path.lowercaseString containsString:@"picker"]) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to INVALID PATH. (%@)", path);
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to invalid path."];
        return NO;
    }
    
    NSDictionary *query = bd_dictionaryFromQuery(URL.query);
    NSString *queryAppID = [query vetyped_stringForKey:kBDAutoTrackAPPID];
    if (![queryAppID isEqualToString:appID]) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to INVALID APPID. (%@)", queryAppID);
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to invalid appId."];
        return NO;
    }
    
    CFTimeInterval queryTime = [query vetyped_doubleForKey:@"time"];
    CFTimeInterval now = bd_currentIntervalValue();
    CFTimeInterval expectedInterval = 60.0;
    if (now - queryTime > expectedInterval) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to TIMEOUT.");
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to time out."];
        return NO;
    }
    
    NSString *qr = [query vetyped_stringForKey:@"qr_param"];
    if (qr.length < 1) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to INVALID qr_param.");
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to invalid param."];
        return NO;
    }
    
    NSString *urlPrefix = [query vetyped_stringForKey:@"url_prefix"];
    [BDAutoTrack trackWithAppID:appID].localConfig.pickerHost= urlPrefix;
    
    NSString *type = [query vetyped_stringForKey:@"type"].lowercaseString;
    if (type == nil) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene terminate due to INVALID type.");
        [BDAutoTrackUI toast:@"OPEN_URL terminate due to invalid type."];
        return NO;
    }
    
    BOOL handled = NO;
    BDSemaphoreLock(self.semaphore);
    BDAutoTrackInternalHandler *handler = [self.internalHandlers objectForKey:type];
    if ([handler respondsToSelector:@selector(handleWithAppID:qrParam:scene:)]) {
        handled = [handler handleWithAppID:appID qrParam:qr scene:scene];
    }
    BDSemaphoreUnlock(self.semaphore);
    
    if (!handled) {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene failure.");
    } else {
        RL_DEBUG(tracker, @"OPEN_URL", @"handleInternalURL:appID:scene successful.");
    }
    
    return handled;
}

- (void)registerInternalHandler:(BDAutoTrackInternalHandler *)handler {
    if (!handler) {
        return;
    }
    NSString *type =handler.type.lowercaseString;
    if (type == nil) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    [self.internalHandlers setValue:handler forKey:type];
    BDSemaphoreUnlock(self.semaphore);
}

- (void)unregisterInternalHandler:(BDAutoTrackInternalHandler *)handler {
    if (!handler) {
        return;
    }
    NSString *type =handler.type.lowercaseString;
    if (type == nil) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    [self.internalHandlers removeObjectForKey:type];
    BDSemaphoreUnlock(self.semaphore);
}


@end
