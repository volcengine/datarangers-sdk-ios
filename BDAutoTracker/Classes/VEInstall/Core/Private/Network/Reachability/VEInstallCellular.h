//
//  VEInstallCelluar.h
//  Masonry
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CTTelephonyNetworkInfo, CTCarrier, CTCellularData;

/// SIM网络状态
typedef NS_ENUM(NSInteger, VEInstallCellularConnectionType) {
    /// 无网络连接
    VEInstallCellularConnectionTypeNone = 0,
    /// 未知移动网络
    VEInstallCellularConnectionTypeUnknown,
    /// 2G网络连接
    VEInstallCellularConnectionType2G,
    /// 3G网络连接
    VEInstallCellularConnectionType3G,
    /// 4G网络连接
    VEInstallCellularConnectionType4G,
    /// 5G网络连接
    VEInstallCellularConnectionType5G,
};

typedef NS_ENUM(NSInteger, VEInstallCellularServiceType) {
    VEInstallCellularServiceTypeNone = 0,         /// 无卡
    VEInstallCellularServiceTypePrimary = 1,      /// 主卡状态
    VEInstallCellularServiceTypeSecondary = 2,    /// 副卡状态
};

@interface VEInstallCellular : NSObject

@property (class ,nonatomic, strong, readonly) CTCellularData *cellularData;

+ (instancetype)sharedInstance;

+ (CTTelephonyNetworkInfo *)telephoneInfo;

/// 返回指定卡信息
/// 如果指定副卡不存在，返回主卡信息
- (VEInstallCellularConnectionType)cellularConnectionTypeForService:(VEInstallCellularServiceType)service;
- (CTCarrier *)carrierForService:(VEInstallCellularServiceType)service;
- (VEInstallCellularServiceType)currentDataServiceType;/// 返回当前流量卡类型

@end

NS_ASSUME_NONNULL_END
