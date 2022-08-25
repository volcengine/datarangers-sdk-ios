//
//  VEInstallDeviceInfo.m
//
//  Created by KiBen on 2019/8/15.
//
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

#import "VEInstallDeviceInfo.h"
#import <UIKit/UIKit.h>
#include <sys/sysctl.h>
#include <sys/mount.h>
#import <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const kIdfaErrorValue = @"00000000-0000-0000-0000-000000000000";
static const NSString *kIPadSystemNamePrefix = @"iPad ";

NSString *newer_version(NSString *a_ver, NSString *b_ver)
{
    if (!a_ver.length) {
        return b_ver;
    }
    if ([a_ver compare:b_ver options:NSNumericSearch] == NSOrderedDescending) {
        // b_ver is lower than the a_ver
        //a_ver相比b_ver是下降的，那么a_ver > b_ver
        return a_ver;
    }
    return b_ver;
}

@implementation VEInstallDeviceInfo

+ (BOOL)isNewerOrEqualTo:(NSString *)version {
    return [[self systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}

+ (BOOL)isNewerOrEqualiOS13
{
    return [self isNewerOrEqualTo:@"13"];
}

+ (BOOL)isNewerOrEqualiOS10
{
    return [self isNewerOrEqualTo:@"10"];
}

+ (BOOL)isNewerOrEqualiOS9
{
    return [self isNewerOrEqualTo:@"9"];
}

+ (BOOL)isNewerOrEqualiOS8
{
    return [self isNewerOrEqualTo:@"8"];
}

+ (BOOL)isiPad {
    static BOOL s_isiPad = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *__model = [UIDevice currentDevice].model;
        s_isiPad = [__model hasPrefix:@"iPad"];
    });
    return s_isiPad;
}

+ (BOOL)isJailBroken {
    
    static BOOL isJailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:@"L0FwcGxpY2F0aW9ucy9DeWRpYS5hcHA="
                                                           options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString *filePath = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            isJailBroken = YES;
        }
        
        data = [[NSData alloc] initWithBase64EncodedString:@"L3ByaXZhdGUvdmFyL2xpYi9hcHQ="
                                                           options:NSDataBase64DecodingIgnoreUnknownCharacters];
        filePath = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            isJailBroken = YES;
        }
    });

    return isJailBroken;
}

+ (NSString *)phoneName {
    const char *original_str = [[UIDevice currentDevice].name UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}

+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return machine;
}

+ (NSString *)resolution {
    CGRect nativeBounds = [[UIScreen mainScreen] nativeBounds];
    return [NSString stringWithFormat:@"%dx%d", (int)nativeBounds.size.width, (int)nativeBounds.size.height];
}

+ (NSString *)systemNameForDeviceType {
    NSString *systemName = [self systemName];
    if ([self isiPad]) {
        systemName = [kIPadSystemNamePrefix stringByAppendingString:systemName];
    }
    return systemName;
}

+ (NSString *)systemRegion {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] ?: @"";
}

+ (NSString *)systemLanguage {
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] ?: @"";
}

+ (NSString *)systemLanguageWithRegion {
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    //systemversion = 10.x 及以下
    if ([systemVersion compare:@"11" options:NSNumericSearch] == NSOrderedAscending) {
        NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSString *str = [NSString stringWithFormat:@"%@_%@", languageCode, countryCode];
        return str;
    }
    //systemversion = 11.0 及以上
    else {
        NSString *firstLanguage = [[NSLocale preferredLanguages]  firstObject];// 当前设置的首选语言
        NSString *languageCode = [[firstLanguage componentsSeparatedByString:@"-"] firstObject];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSString *str = [NSString stringWithFormat:@"%@_%@", languageCode, countryCode];
        return str;
    }
}

+ (NSInteger)timeZone {
    return [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
}

+ (NSString *)timeZoneName {
    return [[NSTimeZone localTimeZone] name];
}

+ (NSInteger)timeZoneOffset {
    return [[NSTimeZone systemTimeZone] secondsFromGMT];
}

+ (NSString *)systemName {
    return [UIDevice currentDevice].systemName;
}

+ (NSString *)systemVersion {
    return [UIDevice currentDevice].systemVersion;
}

+ (NSString *)getSysInfoByName:(char *)typeSpeifier {
    size_t size;
    sysctlbyname(typeSpeifier, NULL, &size, NULL, 0);
    char *answer = (char *) malloc(size);
    sysctlbyname(typeSpeifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    if (results == nil) {
        results = @"";
    }
    free(answer);
    return results;
}

+ (NSString *)platform {
    return [self getSysInfoByName:(char *)"hw.machine"];
}

+ (NSTimeInterval)bootTime {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    sysctl(mib, 2, &boottime, &size, NULL, 0);
    NSTimeInterval bootSec = (NSTimeInterval)boottime.tv_sec + boottime.tv_usec / 1000000.0f;
    return bootSec;
}

+ (NSUInteger)cpuNumbers {
    uint32_t ncpu;
    size_t len = sizeof(ncpu);
    sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
    
    return ncpu;
}

+ (u_int64_t)diskTotalSpace {
    
    if (@available(iOS 11.0, *)) {
        NSDictionary *attrs = [[NSURL fileURLWithPath:NSHomeDirectory()] resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:nil];
        return [attrs[NSURLVolumeAvailableCapacityForImportantUsageKey] unsignedLongLongValue];
    }
    
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
        return 0;
    }
    return [[attrs objectForKey:NSFileSystemSize] unsignedLongLongValue];
}

+ (u_int64_t)physicalMemory {
    return [[NSProcessInfo processInfo] physicalMemory];
}

// idfv获取方法调用多次可能会有数据合规问题，因此做缓存
+ (NSString *)vendorID {
    static dispatch_once_t onceToken;
    static NSString *vendorID = nil;
    dispatch_once(&onceToken, ^{
        vendorID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    });
    return vendorID;
}
@end
