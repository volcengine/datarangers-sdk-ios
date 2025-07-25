//
//  BDAutoTrackNetworkRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDMultiPlatformPrefix.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int32_t, BDAutoTrackNetworkConnectionType) {
    BDAutoTrackNetworkNone = -1,
    BDAutoTrackNetworkConnectionTypeNone = 0,
    BDAutoTrackNetworkConnectionTypeMobile = 1,
    BDAutoTrackNetworkConnectionType2G = 2,
    BDAutoTrackNetworkConnectionType3G = 3,
    BDAutoTrackNetworkConnectionTypeWiFi = 4,
    BDAutoTrackNetworkConnectionType4G = 5,
    BDAutoTrackNetworkConnectionType5G = 6,
};

typedef NS_ENUM(int32_t, BDAutoTrackReachabilityStatus) {
    BDAutoTrackReachabilityStatusNotReachable    = 0,
    BDAutoTrackReachabilityStatusReachableViaWiFi,
    BDAutoTrackReachabilityStatusReachableViaWWAN
};

extern NSNotificationName const BDAutoTrackReachabilityDidChangeNotification;

@interface BDAutoTrackReachability : NSObject

+ (instancetype)reachability;

- (void)startNotifier;

- (void)stopNotifier;

- (BOOL)isNetworkConnected;

- (BDAutoTrackReachabilityStatus)status;

@end

NS_ASSUME_NONNULL_END
