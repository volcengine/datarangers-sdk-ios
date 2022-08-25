//
//  VEInstallReachability+Cellular.h
//  VEInstall
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallReachability.h"
#import "VEInstallCellular.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallReachability (Cellular)

+ (BOOL)isNetworkConnected;

/// 优先返回流量卡状态，其次是主卡状态
+ (VEInstallCellularConnectionType)cellularConnectionType;
+ (BOOL)is2GConnected;
+ (BOOL)is3GConnected;
+ (BOOL)is4GConnected;
+ (BOOL)is5GConnected;
+ (nullable NSString*)carrierName;
+ (nullable NSString*)carrierMCC;
+ (nullable NSString*)carrierMNC;

// 返回指定卡 状态
+ (VEInstallCellularConnectionType)cellularConnectionTypeForService:(VEInstallCellularServiceType)service;
+ (BOOL)is3GConnectedForService:(VEInstallCellularServiceType)service;
+ (BOOL)is4GConnectedForService:(VEInstallCellularServiceType)service;
+ (BOOL)is5GConnectedForService:(VEInstallCellularServiceType)service;
+ (NSString *)carrierNameForService:(VEInstallCellularServiceType)service;
+ (NSString *)carrierMCCForService:(VEInstallCellularServiceType)service;
+ (NSString *)carrierMNCForService:(VEInstallCellularServiceType)service;

@end

NS_ASSUME_NONNULL_END
