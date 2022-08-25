//
//  BDAutoTrackMetricsCollector.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDroneMonitor.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDAutoTrackMetrics : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *category;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSNumber *val;

//统计纬度 以及详情 in params
@property (nonatomic, strong) NSDictionary *dimensions;
//通参
@property (nonatomic, strong) NSDictionary *common;

//启动标识
@property (nonatomic, copy) NSString *launchId;

//预聚合类型
@property (nonatomic, assign) NSUInteger aggregationType;

//预聚合组
@property (nonatomic, copy) NSString *groupId;

//埋点时间
@property (nonatomic, assign) CFTimeInterval time;

//埋点更新,预聚合最后变更时间
@property (nonatomic, assign) CFTimeInterval updateTime;

//埋点自增序列号
@property (nonatomic, assign) uint64_t  metricsIndex;

- (NSArray *)transformSQLiteParameters;

- (void)countIncrease;
- (void)countReset;

- (NSDictionary *)transformLogEvent;

@end

@interface BDAutoTrackMetricsCollector : NSObject

- (instancetype)initWithApplicationId:(NSString *)appId;

- (void)trackMetrics:(NSString *)metricName
               value:(NSNumber *)metricVal
            category:(NSString *)category
          dimensions:(NSDictionary *)dimensions
         aggregation:(BDroneMonitorAggregation *)aggregation
                time:(NSTimeInterval)time;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
