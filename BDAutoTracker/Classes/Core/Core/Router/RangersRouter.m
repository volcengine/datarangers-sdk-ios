//
//  RangersRouter.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersRouter.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackIdentifier.h"
#import "BDAutoTrack+Private.h"

@implementation RangersRouting


+ (instancetype)routing:(NSString *)service
                   base:(NSString *)appId
             parameters:(id)parameters
{
    RangersRouting *routing = [RangersRouting new];
    routing.service = service;
    routing.appId = appId;
    routing.parameters = parameters;
    return routing;
}

- (BOOL)isValid
{
    return self.service.length > 0 && self.appId.length > 0;
}

@end




@implementation RangersRouter {
    
    NSMutableDictionary *ssidByUUID;
    
}

NSMutableDictionary *g_ssid_by_uuid;

+ (void)initialize
{
    g_ssid_by_uuid = [NSMutableDictionary dictionary];
}

+ (id)sync:(RangersRouting *)routing;
{
    if (![routing isValid]) {
        return nil;
    }

    if ([routing.service isEqualToString:@"ssid"]) {
        
        
        
        NSString *existsSSID;
        @synchronized (g_ssid_by_uuid) {
            id dataByAppID = [g_ssid_by_uuid objectForKey:routing.appId];
            existsSSID = [dataByAppID objectForKey:routing.parameters];
        }
        if ([existsSSID length] > 0) {
            return existsSSID;
        }
        
        NSString *userUniqueID = nil;
        if ([routing.parameters isKindOfClass:NSString.class]) {
            userUniqueID = routing.parameters;
        }
        
        NSString *ssid = [[BDAutoTrack trackWithAppID:routing.appId].identifier synchronousfetchSSID:userUniqueID];
        if ([ssid length] > 0) {
            @synchronized (g_ssid_by_uuid) {
                NSMutableDictionary * dataByAppID = [g_ssid_by_uuid objectForKey:routing.appId];
                if (!dataByAppID) {
                    dataByAppID = [NSMutableDictionary dictionary];
                    [g_ssid_by_uuid setValue:dataByAppID forKey:routing.appId];
                }
                [dataByAppID setValue:ssid forKey:routing.parameters];
            }
            return ssid;
        }
        return nil;
    }
    
    return nil;
}

@end
