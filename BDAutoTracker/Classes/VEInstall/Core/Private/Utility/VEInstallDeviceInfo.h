//
//  VEInstallDeviceInfo.h
//
//  Created by KiBen on 2019/8/15.
//
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallDeviceInfo : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)isiPad;
+ (BOOL)isJailBroken;
+ (NSString *)phoneName;
+ (NSString *)deviceModel; //eg: iPhone8,1
+ (NSString *)platform; //eg: x86_64
+ (NSString *)resolution; // 分辨率 eg: 
+ (NSString *)systemName; //eg: iOS
+ (NSString *)systemNameForDeviceType; //eg:iPad_iOS
+ (NSString *)systemVersion; //eg: 12.4
+ (NSString *)systemLanguage; // eg: zh
+ (NSString *)systemRegion; // eg: cn
+ (NSString *)systemLanguageWithRegion; // eg: zh_CN
+ (NSInteger)timeZone; // 时区 值为 -12~12
+ (NSString *)timeZoneName; // 时区名称
+ (NSInteger)timeZoneOffset; // 时区偏移量
+ (NSTimeInterval)bootTime;
+ (NSUInteger)cpuNumbers;
+ (u_int64_t)diskTotalSpace;
+ (u_int64_t)physicalMemory;

+ (BOOL)isNewerOrEqualiOS13;
+ (BOOL)isNewerOrEqualiOS10;
+ (BOOL)isNewerOrEqualiOS9;
+ (BOOL)isNewerOrEqualiOS8;
+ (BOOL)isNewerOrEqualTo:(NSString *)version;
//+ (NSString *)UDID;

// 获取idfv；由于数据合规问题，内部会做缓存
+ (NSString *)vendorID;

@end

NS_ASSUME_NONNULL_END
