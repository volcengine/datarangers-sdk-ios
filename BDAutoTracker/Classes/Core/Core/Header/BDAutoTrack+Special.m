//
//  BDAutoTrack+Special.m
//  RangersAppLog
//
//  Created by bob on 2019/6/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Special.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackDataCenter.h"

#import "BDAutoTrackServiceCenter.h"
#import "RangersLog.h"
#import "BDAutoTrackBatchService.h"

static NSString * const kBDASpecialAppID        = @"second_appid";
static NSString * const kBDASpecialAppName      = @"second_appname";
static NSString * const kBDASpecialType         = @"product_type";
static NSString * const kBDASpecialParams       = @"params_for_special";
static NSString * const BDASpecialParams        = @"second_app";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation BDAutoTrack (Special)

+ (NSDictionary *)specialParamsWitAppID:(NSString *)appID
                                appName:(NSString *)appName
                                   type:(NSString *)productType {
    NSMutableDictionary<NSString *, NSString *> *specialParams = [NSMutableDictionary dictionaryWithObject:BDASpecialParams forKey:kBDASpecialParams];
    [specialParams setValue:appID forKey:kBDASpecialAppID];
    [specialParams setValue:appName forKey:kBDASpecialAppName];
    [specialParams setValue:productType forKey:kBDASpecialType];

    return specialParams;
}

- (BOOL)eventV3:(NSString *)event params:(NSDictionary *)params specialParams:(NSDictionary *)specialParams {
    if (![event isKindOfClass:[NSString class]] || event.length < 1) {
        
        RL_WARN(self.appID, @"terminate event due to EVENT IS EMPTY STRING");
        return NO;
    }

    if (bd_batchIsEventInBlockList(event, self.appID)) {
        RL_WARN(self.appID, @"terminate event due to EVENT IN BLOCK LIST");
        return NO;
    }

    NSString *eventName = [NSString stringWithFormat:@"%@_%@",BDASpecialParams,event];

    if (specialParams.count != 4) {
        RL_WARN(self.appID, @"please user `specialParamsWitAppID:appName:type` to build  specialParams. specialParams(%@)",bd_JSONRepresentation(specialParams));
        return NO;
    }

    if (params && ![NSJSONSerialization isValidJSONObject:params]) {
        RL_WARN(self.appID, @"terminate event due to INVALID PARAMETERS");
        return NO;
    }

    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:specialParams];
    [data addEntriesFromDictionary:[[NSDictionary alloc] initWithDictionary:params copyItems:YES]];
    NSDictionary *trackData = @{kBDAutoTrackEventType:eventName,
                                kBDAutoTrackEventData:data,};

    [self.dataCenter trackUserEventWithData:trackData];
    return YES;
}

- (BOOL)customEvent:(NSString *)category params:(NSDictionary *)params {
    static NSArray<NSString *> *allInternalTables = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allInternalTables = @[BDAutoTrackTableLaunch,
                              BDAutoTrackTableTerminate,
                              BDAutoTrackTableEventV3,
                              BDAutoTrackTableUIEvent,
                              BDAutoTrackTableProfile,
                              BDAutoTrackTableExtraEvent,
                              kBDAutoTrackTracerData,
                              kBDAutoTrackHeader,
                              kBDAutoTrackTimeSync,
                              kBDAutoTrackMagicTag];
    });
    /// 此接口给内部支持log_data使用，但是考虑一下还是加一下check避免异常调用
    NSString *appID = self.appID;
    if (![category isKindOfClass:[NSString class]] ||
        [category stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length < 1) {
        RL_WARN(self.appID, @"terminate event due to ILLEGAL CATEGORY 1. (%@)",category);
        return NO;
    }
    category = [category stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if ([allInternalTables containsObject:category]) {
        RL_WARN(self.appID, @"terminate event due to ILLEGAL CATEGORY 2. (%@)",category);
        return NO;
    }

    if (params && ![NSJSONSerialization isValidJSONObject:params]) {
        RL_WARN(self.appID, @"terminate event due to INVALID PARAMETERS",category);
        return NO;
    }

    [self.dataCenter trackWithTableName:category data:[[NSDictionary alloc] initWithDictionary:params copyItems:YES]];

    return YES;
}

@end

#pragma clang diagnostic pop
