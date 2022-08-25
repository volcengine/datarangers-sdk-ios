//
//  VEInstallConnection.h
//  VEInstall
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 网络状态
typedef NS_ENUM(NSInteger, VEInstallNetworkConnectionType) {
    /// 初始状态
    VEInstallAutoTrackNetworkNone = -1,
    /// 无网络连接
    VEInstallNetworkConnectionTypeNone = 0,
    /// 移动网络连接
    VEInstallNetworkConnectionTypeMobile = 1,
    /// 2G网络连接
    VEInstallNetworkConnectionType2G = 2,
    /// 3G网络连接
    VEInstallNetworkConnectionType3G = 3,
    /// wifi网络连接
    VEInstallNetworkConnectionTypeWiFi = 4,
    /// 4G网络连接
    VEInstallNetworkConnectionType4G = 5,
    /// 5G网络连接
    VEInstallNetworkConnectionType5G = 6,
};

@interface VEInstallConnection : NSObject

@property (nonatomic, assign, readonly) VEInstallNetworkConnectionType connection;
@property (nonatomic, copy, readonly, nullable) NSString *connectMethodName;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
