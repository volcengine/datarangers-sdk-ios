//
//  VEInstallNetworkReachability.h
//  VEInstall
//
//  Created by KiBen on 2021/9/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VEInstallNetworkType) {
    /// 初始状态
    VEInstallNetworkNone = -1,
    /// 无网络连接
    VEInstallNetworkTypeNone = 0,
    /// 移动网络连接
    VEInstallNetworkTypeMobile = 1,
    /// 2G网络连接
    VEInstallNetworkType2G = 2,
    /// 3G网络连接
    VEInstallNetworkType3G = 3,
    /// wifi网络连接
    VEInstallNetworkTypeWiFi = 4,
    /// 4G网络连接
    VEInstallNetworkType4G = 5,
    /// 5G网络连接
    VEInstallNetworkType5G = 6,
};

@interface VEInstallNetworkReachability : NSObject

+ (NSString *_Nullable)carrierName;

+ (NSString *_Nullable)carrierMCC;

+ (NSString *_Nullable)carrierMNC;

+ (VEInstallNetworkType)networkType;
+ (NSString *_Nullable)networkTypeName;

+ (BOOL)isNetworkConnected;

+ (void)addNetworkObserver:(id)observer selector:(SEL)selector;
+ (void)removeNetworkObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END
