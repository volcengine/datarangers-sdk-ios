//
//  TTInstallSandBoxHelper.m
//  Pods
//
//  Created by 冯靖君 on 17/2/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
//

#import "BDAutoTrackSandBoxHelper.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDTrackerCoreConstants.h"

static NSString *const kTTInstallAppVersion = @"kTTInstallAppVersion";
static NSString *const kAppLogInstallAppVersion = @"kAppLogInstallAppVersion";

NSString * bd_sandbox_appDisplayName() {
    static NSString *appName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appName = [[[NSBundle mainBundle] infoDictionary] vetyped_stringForKey:@"CFBundleDisplayName"];
        if (appName == nil) {
            appName = bd_sandbox_appName();
        }
    });

    return appName;
}

 NSString * bd_sandbox_appName() {
    static NSString *appName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appName = [[[NSBundle mainBundle] infoDictionary] vetyped_stringForKey:@"CFBundleName"];
    });

    return appName;
}


NSString *bd_sandbox_releaseVersion() {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


NSString *bd_sandbox_buildVersion() {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

NSString *bd_sandbox_bundleIdentifier() {
    static NSString *bundleIdentifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] vetyped_stringForKey:@"CFBundleIdentifier"];
    });

    return bundleIdentifier;
}

/// 产生header字段user_agent
/// 因为一些历史原因，目前实现将AppName转了latin字符集
NSString *bd_sandbox_userAgent() {
    static NSString * userAgentStr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        NSString *appName = bd_sandbox_appName();
        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding];
        // If we couldn't find one, we'll give up (and ASIHTTPRequest will use the standard CFNetwork user agent)
        if (!appName) {
            appName = @"";
        }

        NSString *appVersion = nil;
        NSString *marketingVersionNumber = bd_sandbox_releaseVersion();
        NSString *developmentVersionNumber = bd_sandbox_buildVersion();
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
        NSString *OSName = BDAutoTrackOSName;
        NSString *OSVersion;
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        deviceName = bd_device_platformName();
        OSVersion = bd_device_systemVersion();

        userAgentStr = [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; %@)", appName, appVersion, deviceName, OSName, OSVersion, locale];
    });

    return userAgentStr;
}

BOOL bd_sandbox_isUpgradeUser() {
    static BOOL isUpgradeUser = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        //记下用户首次安装的版本号
        NSString *preAppVersion = [userDefault stringForKey:kAppLogInstallAppVersion] ?: [userDefault stringForKey:kTTInstallAppVersion];
        if (preAppVersion.length < 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] setObject:bd_sandbox_releaseVersion() forKey:kAppLogInstallAppVersion];
            });
            isUpgradeUser = NO;
        } else if ([bd_sandbox_releaseVersion() isEqualToString:preAppVersion]) {
            isUpgradeUser = NO;
        }

    });

    return isUpgradeUser;
}

