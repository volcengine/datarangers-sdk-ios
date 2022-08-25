//
//  BDroneMonitorDefines.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef BDroneMonitorDefines_h
#define BDroneMonitorDefines_h

NS_ASSUME_NONNULL_BEGIN

typedef NSString *BDroneMonitorCategory NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *BDroneMonitorMetricsName NS_TYPED_EXTENSIBLE_ENUM;



FOUNDATION_EXPORT BDroneMonitorCategory const BDroneNetworkCategory;    //网络

FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkLogSetting;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkDeviceRegistration;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkDeviceActivation;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkProfile;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkABTest;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkALinkDeepLink;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneNetworkALinkDeferredDeepLink;


FOUNDATION_EXPORT BDroneMonitorCategory const BDroneUsageCategory;  //SDK 性能以及使用情况

FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneUsageInitialization;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneUsageStartup;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneUsageDataUploadDelay;
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneUsageAPI;


FOUNDATION_EXPORT BDroneMonitorCategory const BDroneTrackCategory;  //SDK 数据处理流程

FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneTrackEventVolume;        //event 调用量
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneTrackFailureFiltered;    //被过滤
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneTrackFailureSizeLimited; //
FOUNDATION_EXPORT BDroneMonitorMetricsName const BDroneTrackFailureDatabase;    //数据库异常







typedef BOOL (^BDroneMonitorDataLoader)(NSString * _Nonnull appId, NSArray * _Nonnull metricsList);

typedef enum : int {
    MONITOR_AGGREGATION_TYPE_NONE = 0,
    MONITOR_AGGREGATION_TYPE_COUNT,                 //计数
    MONITOR_AGGREGATION_TYPE_COUNT_DISTRIBUTION     //区间分布计数
} MONITOR_AGGREGATION_TYPE;

@interface BDroneMonitorAggregation : NSObject

@property (nonatomic, copy) NSArray<NSNumber *> *intervals;

@property (nonatomic, assign) MONITOR_AGGREGATION_TYPE  aggregationType;

@property (nonatomic, copy) NSArray<NSString *> *fields;

+ (instancetype)countAggregation;

+ (instancetype)distributionAggregation:(NSArray<NSNumber *> *)intervals;
//预聚合指标字段
- (instancetype)addAggregateField:(NSArray<NSString *> *)fields;

@end


@protocol BDroneMonitorTracker <NSObject>

@optional
- (void)presetAggregation:(id)aggregation
               forMetrics:(BDroneMonitorMetricsName)metrics
                 category:(BDroneMonitorCategory)category;


- (void)trackMetrics:(BDroneMonitorMetricsName)metrics
               value:(NSNumber *)metricVal
            category:(BDroneMonitorCategory)category
          dimensions:(nullable NSDictionary *)dimensions;

- (void)uploadUsingBlock:(BOOL (^)(NSArray *eventsList))block;

- (void)flush;

@end

NS_ASSUME_NONNULL_END

#endif /* BDroneMonitorDefines_h */
