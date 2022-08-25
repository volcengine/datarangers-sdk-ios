//
//  BDAutoTrackMetricsCollector.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackMetricsCollector.h"
#import <stdatomic.h>
#import "BDAutoTrackMonitorStore.h"
#import "BDroneDefines.h"

#import "BDroneMonitorDefines.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackParamters.h"

@implementation BDAutoTrackMetrics {
    atomic_long count;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self countReset];
    }
    return self;
}

- (long)count
{
    return count;
}

- (void)countIncrease
{
    count += 1;
    self.val = [NSNumber numberWithLong:count];
}

- (void)countReset
{
    count = 0;
    self.val = [NSNumber numberWithLong:count];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
    [coder encodeObject:self.name forKey:@"metrics_name"];
    [coder encodeObject:self.category forKey:@"metrics_category"];
    [coder encodeObject:self.val forKey:@"metrics_val"];
    [coder encodeObject:self.common forKey:@"common_dict"];
    [coder encodeObject:self.dimensions forKey:@"params_dict"];
    [coder encodeObject:self.launchId forKey:@"launch_id"];
    [coder encodeObject:self.appId forKey:@"app_id"];
    [coder encodeObject:self.groupId forKey:@"group_id"];
    [coder encodeInteger:self.aggregationType forKey:@"aggregation_type"];
    [coder encodeDouble:self.time forKey:@"time"];
    [coder encodeDouble:self.updateTime forKey:@"update_time"];
    [coder encodeObject:[NSNumber numberWithUnsignedLongLong:self.metricsIndex] forKey:@"metrics_index"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        self.name = [coder decodeObjectForKey:@"metrics_name"];
        self.category = [coder decodeObjectForKey:@"metrics_category"];
        self.val = [coder decodeObjectForKey:@"metrics_val"];
        self.common = [coder decodeObjectForKey:@"common_dict"];
        self.dimensions = [coder decodeObjectForKey:@"params_dict"];
        self.launchId = [coder decodeObjectForKey:@"launch_id"];
        self.appId = [coder decodeObjectForKey:@"app_id"];
        self.groupId = [coder decodeObjectForKey:@"group_id"];
        self.aggregationType = [coder decodeIntegerForKey:@"aggregation_type"];
        self.time = [coder decodeDoubleForKey:@"time"];
        self.updateTime = [coder decodeDoubleForKey:@"update_time"];
        
        NSNumber *index = [coder decodeObjectForKey:@"metrics_index"];
        self.metricsIndex = [index unsignedLongLongValue];

    } return self;
}

- (NSArray *)transformSQLiteParameters
{
    NSData *metricsData = [NSKeyedArchiver archivedDataWithRootObject:self];
    if (!metricsData || metricsData.length <= 0) {
        return nil;
    }
//    INSERT INTO monitor_metrics (launchId,appId,name,category,metrics,remark) VALUES (?,?,?,?,?,?);";
    return @[self.launchId?:@""
             ,self.appId?:@""
             ,self.name?:@""
             ,self.category?:@""
             ,metricsData?:[NSNull null]
             ,self.groupId ?:@""
    ];
}

- (void)updateCommon
{
    NSMutableDictionary *common = [NSMutableDictionary dictionary];
    bd_addSharedEventParams(common, self.appId);
    bd_addEventParameters(common);
    
    bd_addScreenOrientation(common, self.appId);
    bd_addGPSLocation(common, self.appId);
    self.common = [common copy];
}

- (NSDictionary *)transformLogEvent
{
    NSDictionary *baseDict =  @{
        @"params_for_special": @"applog_trace",
        @"_staging_flag": @"1",
        @"metrics_name": self.name ?: @"",
        @"metrics_category": self.category ?: @"",
        @"metrics_value": self.val,
        @"launchId": self.launchId ?:@"",
        @"metrics_index": [NSNumber numberWithUnsignedLongLong:self.metricsIndex]
    };
    NSMutableDictionary *dims = [self.dimensions mutableCopy];
    [dims addEntriesFromDictionary:baseDict];
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event addEntriesFromDictionary:self.common?:@{}];
    [event setValue:@"rangersapplog_trace" forKey:kBDAutoTrackEventType];
    [event setValue:[dims copy] forKey:kBDAutoTrackEventData];
    
    return [event copy];
}


@end


@implementation BDAutoTrackMetricsCollector {
    
    NSString *appId;
    BOOL changed;
    CFTimeInterval lastFlushTime;
    
    NSMutableDictionary *aggregationEvents;
    
    atomic_uint_fast64_t metricsIndex;
    
}

- (instancetype)initWithApplicationId:(NSString *)appId_;
{
    if (appId_.length == 0) {
        return nil;
    }
    if (self = [super init]) {
        appId = [appId_ copy];
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    aggregationEvents = [NSMutableDictionary dictionary];
    lastFlushTime =  CFAbsoluteTimeGetCurrent();
    metricsIndex = 0;
}


- (void)trackMetrics:(NSString *)name
               value:(NSNumber *)val
            category:(NSString *)category
          dimensions:(NSDictionary *)dimensions
         aggregation:(BDroneMonitorAggregation *)aggregation
                time:(NSTimeInterval)time
{
    
    @autoreleasepool {
        
        
        NSDictionary *dims = [self transformDimensions:dimensions values:val withAggregation:aggregation];
        
        if (aggregation && aggregation.aggregationType > MONITOR_AGGREGATION_TYPE_NONE) {
            //预聚合埋点缓存
            NSMutableArray *groupValues = [NSMutableArray array];
            [groupValues addObject:name];
            [groupValues addObject:category];
            [aggregation.fields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [groupValues addObject:([dimensions objectForKey:obj] ?:[NSNull null])];
            }];
            if (aggregation.aggregationType == MONITOR_AGGREGATION_TYPE_COUNT_DISTRIBUTION) {
                [groupValues addObject:[dims objectForKey:@"dim_interval_distribution"]?:[NSNull null]];
            }
            
            NSString *groupId = [groupValues componentsJoinedByString:@"-"];
            
            BDAutoTrackMetrics *metrics = [aggregationEvents objectForKey:groupId];
            if (!metrics) {
                metrics = [self generateMetrics];
                metrics.time = time;
                metrics.groupId = groupId;
                metrics.name = name;
                metrics.category = category;
                metrics.dimensions = dims;
                metrics.aggregationType = aggregation.aggregationType;
                @synchronized (self->aggregationEvents) {
                    [aggregationEvents setValue:metrics forKey:groupId];
                }
               
            }
            [metrics countIncrease];
            metrics.updateTime = time;
            self->changed = YES;
            [self flushAggregationMetricsIfNeed];
             
        } else {
            //独立埋点直接落地
            BDAutoTrackMetrics *metrics = [self generateMetrics];
            metrics.time = time;
            metrics.name = name;
            metrics.category = category;
            metrics.val = val;
            metrics.dimensions = dims;
            [[BDAutoTrackMonitorStore sharedStore] enqueue:@[metrics]];
            
        }
    }
}

- (BDAutoTrackMetrics *)generateMetrics
{
    BDAutoTrackMetrics *metrics = [[BDAutoTrackMetrics alloc] init];
    metrics.appId = self->appId;
    metrics.metricsIndex = (++ metricsIndex);
    [metrics updateCommon];
    return metrics;
}

- (NSDictionary *)transformDimensions:(NSDictionary *)dimensions
                                      values:(NSNumber *)val
                             withAggregation:(BDroneMonitorAggregation *)aggregation
{
    if (!dimensions) {
        return nil;
    }
    if (aggregation.aggregationType == MONITOR_AGGREGATION_TYPE_COUNT_DISTRIBUTION) {
        
        
        if ([aggregation.intervals count] > 0) {
            
            __block NSString *intervalCap= @"+";
            __block NSString *intervalFloor= @"0";
            CGFloat doubleV = [val doubleValue];
            
            [aggregation.intervals enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat compareV = [obj doubleValue];
                if (doubleV < compareV) {
                    intervalCap = [NSString stringWithFormat:@"%.0f", compareV];
                    *stop = YES;
                    return;
                }
                intervalFloor =  [NSString stringWithFormat:@"%.0f", compareV];
            }];
            NSMutableDictionary *dims = [dimensions mutableCopy];
            [dims setValue:[NSString stringWithFormat:@"(%@,%@)",intervalFloor,intervalCap] forKey:@"dim_interval_distribution"];
            
            return [dims copy];
        }
        
    }
    return dimensions;
    
}
                

- (void)flush
{
    [self flushAggregationEvents];
}

- (void)flushAggregationEvents
{
    NSArray *events;
    @synchronized (self->aggregationEvents) {
        events = [self->aggregationEvents allValues];
        [[BDAutoTrackMonitorStore sharedStore] enqueue:events];
        [self->aggregationEvents removeAllObjects];
    }
}

- (void)flushAggregationMetricsIfNeed
{
    if (!self->changed) {
        return;
    }
    CFTimeInterval current = CFAbsoluteTimeGetCurrent();
    if (current - lastFlushTime < 60.0f) {
        return;
    }
    [self flushAggregationEvents];
    lastFlushTime = current;
    self->changed = NO;
}




@end
