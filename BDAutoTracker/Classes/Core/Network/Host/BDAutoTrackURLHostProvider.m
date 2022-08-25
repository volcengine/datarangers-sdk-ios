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

/// @return hostURL
/// e.g. @"https://gist.github.com/"s
- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type
                      appID:(NSString *)appID {
    BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(appID);
    BDAutoTrackServiceVendor vendor = settings.serviceVendor;
    if (vendor == nil) {
        return nil;
    }
    
    id<BDAutoTrackURLHostItemProtocol> hostItem = [self.hostItems objectForKey:vendor];
    if (!hostItem) {
        NSCAssert(0, @"vendor is not in the list");
    }
    
    /* 服务端圈选、埋点验证的域名来自二维码，存储于localConfig.pickerHost */
    if (type == BDAutoTrackRequestURLSimulatorLogin ||
        type == BDAutoTrackRequestURLSimulatorLog ||
        type == BDAutoTrackRequestURLSimulatorUpload) {
        NSString *host = settings.pickerHost;
        NSString *path = [hostItem URLPathForURLType:type];
        
        return [self requestURLWithHost:host path:path];
    }
    
    /* 私有化用户可通过URLBlock和HostBlock自定义上报地址 */
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
    
    /* 若无Block或Block未命中，则使用SDK内置上报地址 */
    if (requestURL.length < 1) {
        requestURL = [hostItem URLForURLType:type];
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
