//
//  VEInstallRequestParamUtility.m
//  VEInstall
//
//  Created by KiBen on 2019/9/27.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallRequestParamUtility.h"
#import "VEInstall.h"
#import "VEInstallVersion.h"
#import "VEInstallNetworkReachability.h"
#import "VEInstallDeviceInfo.h"
#import <objc/message.h>

@implementation VEInstallRequestParamUtility

+ (NSDictionary *)registerDeviceParametersForCurrentInstall:(VEInstall *)install {
    
    NSMutableDictionary *header = @{
        @"bd_did" : install.deviceID ?: @"",
        @"install_id" : install.installID ?: @"",
        @"ssid" : install.ssID ?: @"",
        @"cd" : install.cdValue ?: @"",
        @"sdk_version" : @(kVEInstallVersionCode),
        @"os" : @"iOS",
        @"platform" : @"iOS",
        @"app_name" : install.installConfig.name ?: @"",
        @"app_region" : [VEInstallDeviceInfo systemRegion] ?: @"",
        @"os_version" : [[UIDevice currentDevice] systemVersion] ?: @"",
        @"device_model" : [VEInstallDeviceInfo deviceModel] ?: @"",
        @"device_platform" : [UIDevice currentDevice].model ?: @"",
        @"resolution" : [VEInstallDeviceInfo resolution] ?: @"",
        @"app_language" : [VEInstallDeviceInfo systemLanguage] ?: @"",
        @"language" : [VEInstallDeviceInfo systemLanguage] ?: @"",
        @"timezone" : @([VEInstallDeviceInfo timeZone]) ?: @"",
        @"access" : [VEInstallNetworkReachability networkTypeName] ?: @"",
        @"aid" : install.installConfig.appID ?: @"",
        @"display_name": [self appDisplayName] ?: @"",
        @"app_version" :  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"",
        @"channel" : install.installConfig.channel ?: @"",
        @"package": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] ?: @"",
        @"carrier" : [VEInstallNetworkReachability carrierName] ?: @"",
        @"mcc_mnc" : [NSString stringWithFormat:@"%@%@", [VEInstallNetworkReachability carrierMCC], [VEInstallNetworkReachability carrierMNC]],
        @"region" : [VEInstallDeviceInfo systemRegion] ?: @"",
        @"phone_name" : [VEInstallDeviceInfo phoneName] ?: @"",
        @"timezone_name" : [VEInstallDeviceInfo timeZoneName] ?: @"",
        @"timezone_offset" : @([VEInstallDeviceInfo timeZoneOffset]),
        @"sdk_version_code" : [self sdkVersionCode] ?: @"",
        @"app_version_minor" : [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"] ?: @"",
        @"is_jailbroken": @([VEInstallDeviceInfo isJailBroken]),
        @"is_upgrade_user": @([self isUpgradeUser]),
        @"sdk_lib" : @"iOS",
        @"sdk_version" : @(kVEInstallVersionCode),
        @"sdk_version_code" : [self sdkVersionCode] ?: @"",
        @"user_agent" : [self userAgentString] ?: @"",
        @"vendor_id" : [VEInstallDeviceInfo vendorID] ?: @"",
        veinstall_idfa_mask() : [self idfa] ?: @"",
        @"user_unique_id" : install.installConfig.userUniqueID ?: [NSNull null]
    }.mutableCopy;
    
    // 业务方自定义header参数
    VEInstallCustomParamsBlock paramBlock = [install.installConfig.customHeaderBlock copy];
    if (paramBlock) {
        header[@"custom"] = paramBlock();
    }
    
    NSDictionary *parameter =
    @{
        @"header" : header,
        @"magic_tag" : @"ss_app_log"
    };
    return parameter;
}

+ (NSDictionary *)activateDeviceParametersForCurrentInstall:(VEInstall *)install {
    
    NSMutableDictionary *parameters = @{
        @"aid" : install.installConfig.appID ?: @"",
        @"app_language" : [VEInstallDeviceInfo systemLanguage] ?: @"",
        @"app_name": install.installConfig.name ?: @"",
        @"app_region" : [VEInstallDeviceInfo systemRegion] ?: @"",
        @"app_version" :  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"",
        @"bd_did" : install.deviceID ?: @"",
        @"channel" : install.installConfig.channel ?: @"",
        @"device_model" : [VEInstallDeviceInfo deviceModel] ?: @"",
        @"device_platform" : [UIDevice currentDevice].model ?: @"",
        veinstall_idfa_mask() : [self idfa] ?: @"",
        @"vid" : [UIDevice currentDevice].identifierForVendor.UUIDString ?: @"",
        @"install_id" : install.installID ?: @"",
        @"iid" : install.installID ?: @"",
        @"is_upgrade_user": @([self isUpgradeUser]),
        @"os" : @"iOS",
        @"os_version" : [[UIDevice currentDevice] systemVersion] ?: @"",
        @"platform" : @"iOS",
        @"sdk_lib" : @"iOS",
        @"sdk_version" : @(kVEInstallVersionCode),
        @"sdk_version_code" : [self sdkVersionCode] ?: @"",
        @"user_agent" : [self userAgentString] ?: @"",
        @"user_unique_id" : install.installConfig.userUniqueID ?: [NSNull null],
        @"version_code" :  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"",
    }.mutableCopy;
    
    return parameters.copy;
}

+ (NSString *)appDisplayName {
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return appName;
}

+ (NSString *)userAgentString {
    
    static dispatch_once_t onceToken;
    static NSString *userAgent = @"";
    dispatch_once(&onceToken, ^{
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        // Attempt to find a name for this application
        NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        if (!appName) {
            appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        }
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding];
        
        // If we couldn't find one, we'll give up (and ASIHTTPRequest will use the standard CFNetwork user agent)
        if (!appName) {
            return;
        }
        
        NSString *appVersion = nil;
        NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (marketingVersionNumber && developmentVersionNumber) {
            if ([marketingVersionNumber isEqualToString:developmentVersionNumber]) {
                appVersion = marketingVersionNumber;
            } else {
                appVersion = [NSString stringWithFormat:@"%@ rv:%@",marketingVersionNumber,developmentVersionNumber];
            }
        } else {
            appVersion = (marketingVersionNumber ? marketingVersionNumber : developmentVersionNumber);
        }
        
        NSString *deviceName;
        NSString *OSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        
        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        OSName = [device systemName];
        OSVersion = [device systemVersion];
        
        userAgent = [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@)", appName, appVersion, deviceName, OSName, OSVersion, locale];
    });
    
    return userAgent;
}

+ (BOOL)isUpgradeUser {
    
    static NSString *const kTTInstallAppVersion = @"kTTInstallAppVersion";
    static NSString *const kAppLogInstallAppVersion = @"kAppLogInstallAppVersion";
    
    static BOOL isUpgradeUser = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        
        // 兼容原先AppLog里的判断
        NSString *preAppVersion = [userDefault stringForKey:@"kAppLogInstallAppVersion"] ?: [userDefault stringForKey:@"kTTInstallAppVersion"];
        if (preAppVersion) {
            preAppVersion = [userDefault stringForKey:@"kVEInstallAppVersion"];
        }
        
        //记下用户首次安装的版本号
        NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
        if (!preAppVersion) {
            [userDefault setObject:currentVersion forKey:@"kVEInstallAppVersion"];
            isUpgradeUser = NO;
        } else if ([preAppVersion isEqualToString:currentVersion]) {
            isUpgradeUser = NO;
        }

    });

    return isUpgradeUser;
}

+ (NSString *)sortedQueryEncodedStringWithParameter:(NSDictionary *)parameter {
    
    NSMutableArray *keyValues = [NSMutableArray arrayWithCapacity:parameter.allKeys.count];
    NSArray *sortedKeys = [parameter.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *sortedKey in sortedKeys) {
        [keyValues addObject:[NSString stringWithFormat:@"%@=%@", sortedKey, parameter[sortedKey]]];
    }
    NSString *queryString = [keyValues componentsJoinedByString:@"&"];
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:@","]; // 仅对,做编码
    NSString *encodedString = [queryString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    return encodedString;
}

+ (NSString *)idfa {
    
    static dispatch_once_t onceToken;
    static NSString *_idfa = nil;
    dispatch_once(&onceToken, ^{
        Class idfaClass = NSClassFromString(@"VEInstallIDFAManager");
        if (idfaClass) {
            NSString *(*trackingIdentifierFunc)(id, SEL) = (NSString *(*)(id, SEL))objc_msgSend;
            _idfa = trackingIdentifierFunc(idfaClass, @selector(trackingIdentifier));
        }
    });
    return _idfa;
}

// 约定的规则
+ (NSNumber *)sdkVersionCode {
    NSArray *components = [kVEInstallVersion componentsSeparatedByString:@"."];
    if (components.count < 3) {
        return @(10000000);
    }
    return @(10000000 + [components.firstObject integerValue] * 10000 + [components[1] integerValue] * 100 + [components.lastObject integerValue]);
}

+ (NSDictionary *)extraParams {
    
    static dispatch_once_t onceToken;
    static NSDictionary *_extraParams = nil;
    dispatch_once(&onceToken, ^{
        Class extraParamsClass = NSClassFromString(@"VEInstallExtraParams");
        if (extraParamsClass) {
            NSDictionary *(*extraParamsFunc)(id, SEL) = (NSDictionary *(*)(id, SEL))objc_msgSend;
            _extraParams = extraParamsFunc(extraParamsClass, @selector(extraParams));
        }
    });
    return _extraParams;
}

static NSString *veinstall_ral_base64_string(NSString *base64) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64
                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return @"";
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

static NSString *veinstall_idfa_mask() {
    // idfa
    return veinstall_ral_base64_string(@"aWRmYQ==");
}

@end
