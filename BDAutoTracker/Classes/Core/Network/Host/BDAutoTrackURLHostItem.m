//
//  BDAutoTrackURLHostItem.m
//  RangersAppLog
//
//  Created by bob on 2020/8/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackURLHostItem.h"
#import "BDAutoTrackLocalConfigService.h"

// Request URL Type


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

/// 获得对应URL类型的URL path，用于组装完整的URL。
/// @return 对应URL类型的URL path
/// @param type URL类型的枚举。
- (NSString *)URLPathForURLType:(BDAutoTrackRequestURLType)type {
    switch (type) {
        case BDAutoTrackRequestURLSettings:      return @"service/2/log_settings/";
        case BDAutoTrackRequestURLABTest:       return @"service/2/abtest_config/";
        case BDAutoTrackRequestURLRegister:      return @"service/2/device_register/";
        case BDAutoTrackRequestURLActivate:      return @"service/2/app_alert_check/";
        case BDAutoTrackRequestURLLog:
        case BDAutoTrackRequestURLLogBackup:       return @"service/2/app_log/";
        case BDAutoTrackRequestURLProfile:         return @"service/2/profile/";

        case BDAutoTrackRequestURLSimulatorLogin:   return @"simulator/mobile/login";
        case BDAutoTrackRequestURLSimulatorUpload:     return @"simulator/mobile/layout";
        case BDAutoTrackRequestURLSimulatorLog:     return @"simulator/mobile/log";
            
        case BDAutoTrackRequestURLALinkLinkData: return @"service/2/alink_data";
        case BDAutoTrackRequestURLALinkAttributionData: return @"service/2/attribution_data";
    }

    return @"";
}

- (NSString *)URLHostForURLType:(BDAutoTrackRequestURLType)type {
    NSString *host = [self hostDomain];
    NSString *thirdLevelDomain = [self thirdLevelDomainForURLType:type];
    
    return [NSString stringWithFormat:@"https://%@.%@", thirdLevelDomain, host];
}

/// 获得对应URL类型的三级域名，用于组装完整的URL。
/// @return 对应URL类型的三级域名
/// @param type URL类型的枚举。
- (NSString *)thirdLevelDomainForURLType:(BDAutoTrackRequestURLType)type {
    NSString *thirdLevelDomain;
    switch (type) {
        case BDAutoTrackRequestURLRegister:
        case BDAutoTrackRequestURLActivate:
        case BDAutoTrackRequestURLSettings:
        case BDAutoTrackRequestURLABTest:
        case BDAutoTrackRequestURLLog:
        case BDAutoTrackRequestURLProfile:
            thirdLevelDomain = @"toblog";
            break;
        
        /* 日志上报备份URL */
        case BDAutoTrackRequestURLLogBackup:
            thirdLevelDomain = @"tobapplog";
            break;
        
        /* 服务端圈选的上报host来自二维码 */
        case BDAutoTrackRequestURLSimulatorLogin:
        case BDAutoTrackRequestURLSimulatorLog:
        case BDAutoTrackRequestURLSimulatorUpload:
            break;
        
        /* ALink */
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
