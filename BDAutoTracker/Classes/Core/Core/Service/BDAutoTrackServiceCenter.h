//
//  BDAutoTrackServiceCenter.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDAutoTrackService;

@interface BDAutoTrackServiceCenter : NSObject

+ (instancetype)defaultCenter;

#pragma mark - commom use

- (void)registerService:(id<BDAutoTrackService>)service;
- (void)unregisterService:(id<BDAutoTrackService>)service;
- (nullable id<BDAutoTrackService>)serviceForName:(NSString *)serviceName appID:(NSString *)appID;
- (void)unregisterAllServices;

- (nullable NSArray<id<BDAutoTrackService>> *)servicesForName:(NSString *)serviceName;

@end

FOUNDATION_EXTERN id<BDAutoTrackService> _Nullable bd_standardServices(NSString *serviceName, NSString *appID);

NS_ASSUME_NONNULL_END
