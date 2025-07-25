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
    BDAutoTrackConnectionTypeUnknown = -1,
    BDAutoTrackConnectionTypeNone = 0,
    BDAutoTrackConnectionTypeMobile = 1,
    BDAutoTrackConnectionType2G = 2,
    BDAutoTrackConnectionType3G = 3,
    BDAutoTrackConnectionTypeWiFi = 4,
    BDAutoTrackConnectionType4G = 5,
    BDAutoTrackConnectionType5G = 6
};



@class BDAutoTrackReachability;
@interface BDAutoTrackEnviroment : NSObject

@property (nonatomic, readonly) BDAutoTrackReachability *reachability;

+ (instancetype)sharedEnviroment;

- (void)startTrack;


- (BOOL)isNetworkConnected;

- (NSString *)connectionTypeName;

- (BDAutoTrackConnectionType)connectionType;

@end

NS_ASSUME_NONNULL_END
