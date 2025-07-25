//
//  RangersRouter.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersRouter.h"
#import "BDTrackerCoreConstants.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrack+Private.h"

@implementation RangersRouting


+ (instancetype)routing:(NSString *)service
                   base:(NSString *)appId
             parameters:(id)parameters
{
    RangersRouting *routing = [RangersRouting new];
    routing.service = service;
    routing.appId = appId;
    routing.parameters = [parameters copy];
    return routing;
}

- (BOOL)isValid
{
    return self.service.length > 0 && self.appId.length > 0;
}

@end




#import "BDAutoTrackRegisterRequest.h"

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
        
        id uuid = [routing.parameters objectForKey:kBDAutoTrackEventUserID];
        NSString *uuid_str = @"";
        if ([uuid isKindOfClass:NSString.class]) {
            uuid_str = uuid;
        }
        
        NSString *existsSSID;
        @synchronized (g_ssid_by_uuid) {
            id dataByAppID = [g_ssid_by_uuid objectForKey:routing.appId];
            existsSSID = [dataByAppID objectForKey:uuid_str];
        }
        if ([existsSSID length] > 0) {
            return existsSSID;
        }
        
        BDAutoTrackRegisterRequest *request =  [[BDAutoTrackRegisterRequest alloc] initWithAppID:routing.appId];
        request.requestType = BDAutoTrackRequestURLRegister;

        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:request.appID];
        
        RL_INFO(tracker,@"[Network]",@"FIX SSID when uploading...");
        id JSON = [request syncRegister:routing.parameters];
        NSString *ssid = [JSON vetyped_stringForKey:kBDAutoTrackSSID];
        if ([ssid isKindOfClass:NSString.class] && [ssid length] > 0) {
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
