#import <Foundation/Foundation.h>
#import "BDMultiPlatformPrefix.h"

NS_ASSUME_NONNULL_BEGIN

//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
/// 网络状态
typedef NS_ENUM(int32_t, BDAutoTrackNetworkConnectionType) {
    /// 初始状态
    BDAutoTrackNetworkNone = -1,
    /// 无网络连接
    BDAutoTrackNetworkConnectionTypeNone = 0,
    /// 移动网络连接
    BDAutoTrackNetworkConnectionTypeMobile = 1,
    /// 2G网络连接
    BDAutoTrackNetworkConnectionType2G = 2,
    /// 3G网络连接
    BDAutoTrackNetworkConnectionType3G = 3,
    /// wifi网络连接
    BDAutoTrackNetworkConnectionTypeWiFi = 4,
    /// 4G网络连接
    BDAutoTrackNetworkConnectionType4G = 5,
    /// 5G网络连接
    BDAutoTrackNetworkConnectionType5G = 6,
};

typedef NS_ENUM(int32_t, BDAutoTrackReachabilityStatus) {
    BDAutoTrackReachabilityStatusNotReachable    = 0,
    BDAutoTrackReachabilityStatusReachableViaWiFi,
    BDAutoTrackReachabilityStatusReachableViaWWAN
};

extern NSNotificationName const BDAutoTrackReachabilityChangedNotification;

@interface BDAutoTrackReachability : NSObject

+ (instancetype)reachability;

- (void)startNotifier;

- (void)stopNotifier;

- (BOOL)isNetworkConnected;

- (BDAutoTrackReachabilityStatus)status;

@end

NS_ASSUME_NONNULL_END
