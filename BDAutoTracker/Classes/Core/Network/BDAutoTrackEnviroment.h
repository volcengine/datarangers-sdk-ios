//
//  BDAutoTrackEnviroment.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/26.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDAutoTrackConnectionType) {
    /// 初始状态
    BDAutoTrackConnectionTypeUnknown = -1,
    /// 无网络连接
    BDAutoTrackConnectionTypeNone = 0,
    /// 移动网络连接
    BDAutoTrackConnectionTypeMobile = 1,
    /// 2G网络连接
    BDAutoTrackConnectionType2G = 2,
    /// 3G网络连接
    BDAutoTrackConnectionType3G = 3,
    /// wifi网络连接
    BDAutoTrackConnectionTypeWiFi = 4,
    /// 4G网络连接
    BDAutoTrackConnectionType4G = 5,
    /// 5G网络连接
    BDAutoTrackConnectionType5G = 6
};



@class BDAutoTrackReachability;
@interface BDAutoTrackEnviroment : NSObject

@property (nonatomic, readonly) BDAutoTrackReachability *reachability;

+ (instancetype)sharedEnviroment;

- (void)startTrack;


//network
- (BOOL)isNetworkConnected;

/**
 * JSONObject for CTCarrier
 */
- (id)carrier;

- (NSString *)connectionTypeName;

- (BDAutoTrackConnectionType)connectionType;

@end

NS_ASSUME_NONNULL_END
