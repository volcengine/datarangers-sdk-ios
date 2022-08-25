//
//  BDAutoTrackABTest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackABTest : BDAutoTrackService

@property (nonatomic, assign) BOOL abtestEnabled;

@property (nonatomic, copy) NSDictionary *currentRawData;

@property (nonatomic, assign) NSTimeInterval manualPullInterval;
@property (nonatomic, assign) NSTimeInterval lastManualPullTime;


- (instancetype)initWithAppID:(NSString *)appID;

- (nullable id)getConfig:(NSString *)key defaultValue:(nullable id)defaultValue;
- (nullable NSString *)allABVersions;

- (NSDictionary *)allABTestConfigs;
/// `allABTestConfigs` version 2. Align with web and Android.
/// return raw key-value in server response.
- (NSDictionary *)allABTestConfigs2;

- (void)updateABConfigWithRawData:(nullable NSDictionary<NSString *, NSDictionary *> *)rawData postNotification:(BOOL)postNoti;

/// pass nil to remove external AB versions
- (void)setExternalABVersion:(nullable NSString *)versions;

/// launch\terminate\eventV3\UIEvent 事件参数
- (NSString *)sendableABVersions;

- (void)setALinkABVersions:(nullable NSString *)ALinkPBABVersions;

- (void)pullABTesting:(BOOL)manually;

@end

NS_ASSUME_NONNULL_END
