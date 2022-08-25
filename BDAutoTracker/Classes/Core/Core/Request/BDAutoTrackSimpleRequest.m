//
//  BDAutoTrackSimpleRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSimpleRequest.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDCommonDefine.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackURLHostProvider.h"
#import "NSDictionary+VETyped.h"

@implementation BDAutoTrackSimpleRequest

- (instancetype)initWithAppID:(NSString *)appID type:(BDAutoTrackRequestURLType)type {
    self = [super initWithAppID:appID];
    if (self) {
        self.requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:type appID:appID];
    }
    
    return self;
}

- (NSDictionary *)responseFromData:(NSData *)data error:(NSError *)error {
    NSDictionary *response = [super responseFromData:data error:error];
    
    if ([response isKindOfClass:[NSDictionary class]]
        && response.count > 0
        && [response vetyped_integerForKey:@"status"] == 0)  {
        return [response vetyped_dictionaryForKey:@"data"];
    }
    
    return nil;
}

- (NSMutableDictionary *)requestParameters {
    NSMutableDictionary *result = [super requestParameters];
    
    [result setValue:self.qr forKey:@"qr_param"];
    NSDictionary *parameters = self.parameters;
    if ([parameters isKindOfClass:[NSDictionary class]]
        && parameters.count > 0) {
        [result addEntriesFromDictionary:parameters];
    }
    [result setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];
    [result setValue:bd_timeSync() forKey:kBDAutoTrackTimeSync];
    
    return result;
}

- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *header = [super requestHeaderParameters];
    [header setValue:@(BDAutoTrackerSDKVersion) forKey:kBDPickerSDKVersion];
    CGSize resolution = CGSizeZero;
#if TARGET_OS_IOS
    resolution = [[UIScreen mainScreen] bounds].size;
#elif TARGET_OS_OSX
    resolution = [NSScreen mainScreen].frame.size;
#endif
    [header setValue:@((int)(resolution.width)) forKey:@"width"];
    [header setValue:@((int)(resolution.height)) forKey:@"height"];
    
    return header;
}

@end
