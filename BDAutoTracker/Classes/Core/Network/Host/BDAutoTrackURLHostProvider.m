//
//  BDAutoTrackURLHostProvider.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackURLHostProvider.h"
#import <objc/runtime.h>
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackURLHostItemPrivate.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrack+Private.h"

@interface BDAutoTrackURLHostProvider ()

@property (strong, nonatomic) NSMutableDictionary<BDAutoTrackServiceVendor, id<BDAutoTrackURLHostItemProtocol>> *hostItems;

@end

@implementation BDAutoTrackURLHostProvider

+ (instancetype)sharedInstance {
    static BDAutoTrackURLHostProvider *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hostItems = [NSMutableDictionary dictionaryWithCapacity:5];
        [self registerHostItem:[BDAutoTrackURLHostItemPrivate new]];
    }
    
    return self;
}

- (NSString *)requestURLWithHost:(NSString *)host path:(NSString *)path {
    if (host.length < 1) {
        return nil;
    }
    
    if ([host hasSuffix:@"/"]) {
        return [NSString stringWithFormat:@"%@%@",host, path];
    } else {
        return [NSString stringWithFormat:@"%@/%@",host, path];
    }
}

- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type
                      appID:(NSString *)appID {
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    BDAutoTrackLocalConfigService *settings = tracker.localConfig;
    BDAutoTrackServiceVendor vendor = settings.serviceVendor;
    if (vendor == nil) {
        return nil;
    }
    
    id<BDAutoTrackURLHostItemProtocol> hostItem = [self.hostItems objectForKey:vendor];
    if (!hostItem) {
        NSCAssert(0, @"vendor is not in the list");
    }
    
    if (type == BDAutoTrackRequestURLSimulatorLogin ||
        type == BDAutoTrackRequestURLSimulatorLog ||
        type == BDAutoTrackRequestURLSimulatorUpload) {
        NSString *host = settings.pickerHost;
        NSString *path = [hostItem URLPathForURLType:type];
        
        return [self requestURLWithHost:host path:path];
    }
    
    NSString *url = @"";
    if (tracker.identifier.isAuthorized) {
        url = [self createAdvertisingRequestURL:settings type:type];
    }
    if (url.length == 0) { //use default url
        url = [self createRequestURL:settings type:type];
    }
    return url;
}

- (NSString *)createRequestURL:(BDAutoTrackLocalConfigService *)settings type:(BDAutoTrackRequestURLType)type
{
    BDAutoTrackServiceVendor vendor = settings.serviceVendor;
    id<BDAutoTrackURLHostItemProtocol> hostItem = [self.hostItems objectForKey:vendor];
    
    BDAutoTrackRequestURLBlock requestURLBlock = settings.requestURLBlock;
    NSString *requestURL = nil;
    if (requestURLBlock) {
        requestURL = requestURLBlock(vendor, type);
        requestURL = bd_validateRequestURL(requestURL);
    }
    
    BDAutoTrackRequestHostBlock requestHostBlock = settings.requestHostBlock;
    if (requestURL.length < 1 && requestHostBlock) {
        NSString *host = requestHostBlock(vendor, type);
        NSString *path = [hostItem URLPathForURLType:type];
        
        requestURL = [self requestURLWithHost:host path:path];
    }
    
    if (requestURL.length < 1) {
        requestURL = [hostItem URLForURLType:type];
    }

    return requestURL;
}

- (NSString *)createAdvertisingRequestURL:(BDAutoTrackLocalConfigService *)settings type:(BDAutoTrackRequestURLType)type
{
    BDAutoTrackServiceVendor vendor = settings.serviceVendor;
    id<BDAutoTrackURLHostItemProtocol> hostItem = [self.hostItems objectForKey:vendor];
    
    BDAutoTrackRequestURLBlock requestURLBlock = settings.requestAdvertisingURLBlock;
    NSString *requestURL = nil;
    if (requestURLBlock) {
        requestURL = requestURLBlock(vendor, type);
        requestURL = bd_validateRequestURL(requestURL);
    }
    
    BDAutoTrackRequestHostBlock requestHostBlock = settings.requestAdvertisingHostBlock;
    if (requestURL.length < 1 && requestHostBlock) {
        NSString *host = requestHostBlock(vendor, type);
        NSString *path = [hostItem URLPathForURLType:type];
        
        requestURL = [self requestURLWithHost:host path:path];
    }
    
    return requestURL;
}

- (BOOL)registerHostItem:(id<BDAutoTrackURLHostItemProtocol>)hostItem {
    BDAutoTrackServiceVendor vendor = [hostItem vendor];
    if (hostItem && vendor) {
        [self.hostItems setObject:hostItem forKey:vendor];
        return YES;
    }
    
    return NO;
}

@end
