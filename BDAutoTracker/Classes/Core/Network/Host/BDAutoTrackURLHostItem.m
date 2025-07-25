//
//  BDAutoTrackURLHostItem.m
//  RangersAppLog
//
//  Created by bob on 2020/8/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackURLHostItem.h"
#import "BDAutoTrackLocalConfigService.h"

@implementation BDAutoTrackURLHostItem

- (BDAutoTrackServiceVendor)vendor {
    return nil;
}

- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type {
    NSString *host = [self URLHostForURLType:type];
    NSString *path = [self URLPathForURLType:type];
    if ([host hasSuffix:@"/"]) {
        return [NSString stringWithFormat:@"%@%@",host, path];
    } else {
        return [NSString stringWithFormat:@"%@/%@",host, path];
    }
}

- (NSString *)URLPathForURLType:(BDAutoTrackRequestURLType)type {
    switch (type) {
        case BDAutoTrackRequestURLSettings:      return @"service/2/log_settings/";
        case BDAutoTrackRequestURLABTest:       return @"service/2/abtest_config/";
        case BDAutoTrackRequestURLRegister:      return @"service/2/device_register/";
        case BDAutoTrackRequestURLLog:
        case BDAutoTrackRequestURLLogBackup:       return @"service/2/app_log/";
        case BDAutoTrackRequestURLProfile:         return @"service/2/profile/";

        case BDAutoTrackRequestURLSimulatorLogin:   return @"simulator/mobile/login";
        case BDAutoTrackRequestURLSimulatorUpload:     return @"simulator/mobile/layout";
        case BDAutoTrackRequestURLSimulatorLog:     return @"simulator/mobile/log";
            
        case BDAutoTrackRequestURLALinkLinkData: return @"service/2/alink_data";
        case BDAutoTrackRequestURLALinkAttributionData: return @"service/2/attribution_data";
            
        case BDAutoTrackRequestURLOneIDBind: return @"service/2/id_bind";
        case BDAutoTrackRequestURLABTestLocalShuntVersionInfo: return @"service/2/abtest_config/get_client_local_shunt_version_info";
    }

    return @"";
}

- (NSString *)URLHostForURLType:(BDAutoTrackRequestURLType)type {
    NSString *host = [self hostDomain];
    NSString *thirdLevelDomain = [self thirdLevelDomainForURLType:type];
    
    return [NSString stringWithFormat:@"https://%@.%@", thirdLevelDomain, host];
}

- (NSString *)thirdLevelDomainForURLType:(BDAutoTrackRequestURLType)type {
    NSString *thirdLevelDomain;
    switch (type) {
        case BDAutoTrackRequestURLRegister:
        case BDAutoTrackRequestURLSettings:
        case BDAutoTrackRequestURLABTest:
        case BDAutoTrackRequestURLLog:
        case BDAutoTrackRequestURLProfile:
        case BDAutoTrackRequestURLOneIDBind:
            thirdLevelDomain = @"toblog";
            break;
        
        case BDAutoTrackRequestURLLogBackup:
            thirdLevelDomain = @"tobapplog";
            break;
        
        case BDAutoTrackRequestURLSimulatorLogin:
        case BDAutoTrackRequestURLSimulatorLog:
        case BDAutoTrackRequestURLSimulatorUpload:
            break;
        
        case BDAutoTrackRequestURLALinkLinkData:
        case BDAutoTrackRequestURLALinkAttributionData:
            thirdLevelDomain = @"toblog-alink";
            break;
        
        default:
            break;
    }
    return thirdLevelDomain;
}

- (NSString *)hostDomain {
    return nil;
}

@end
