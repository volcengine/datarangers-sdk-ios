//
//  BDroneMonitor.m
//  Drone
//
//  Created by SoulDiver on 2022/4/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDroneMonitor.h"

NS_ASSUME_NONNULL_BEGIN
@class BDroneMonitorAggregation,BDAutoTrackMetrics;


@interface BDroneMonitor : NSObject


+ (instancetype)moduleWithTracker:(id)tracker;

/*!
 *  @abstract 预设置埋点聚合类型
 *  @param category 指标类别
 *  @param metrics  指标名称
 *  @param aggregation 聚合描述
 *
 */
- (void)presetAggregation:(BDroneMonitorAggregation *)aggregation
               forMetrics:(NSString *)metrics
                 category:(NSString *)category;


/*!
 *  @abstract 统计数据指标
 *  @param category 指标类别
 *  @param metrics  指标名称
 *  @param metricVal 指标名称
 *  @param dimensions 纬度字段
 *
 */
- (void)trackMetrics:(NSString *)metrics
               value:(NSNumber *)metricVal
            category:(NSString *)category
          dimensions:(nullable NSDictionary *)dimensions;


- (void)flush;

- (void)uploadUsingBlock:(BOOL (^)(NSArray *eventsList))block;

+ (instancetype)new __attribute__((unavailable()));
- (instancetype)init __attribute__((unavailable()));

@end

NS_ASSUME_NONNULL_END

