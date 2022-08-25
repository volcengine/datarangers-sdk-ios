//
//  BDroneMonitor.m
//  Drone
//
//  Created by SoulDiver on 2022/4/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDroneMonitor.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackMetricsCollector.h"
#import "BDroneDefines.h"
#import "BDAutoTrackMonitorStore.h"

#import "BDroneMonitorDefines.h"
#import "RangersLog.h"


#pragma mark - BDroneMonitor

@interface BDroneMonitor ()<BDroneModule> {
    BOOL changed;
    dispatch_queue_t monitorQueue;
    void* onMonitorQueueTag;
    
    BDAutoTrackMetricsCollector *collector;
    
    NSMutableDictionary *presetAggregations;
}

@property (nonatomic, weak) id tracker;

@end

@implementation BDroneMonitor



- (void)uploadUsingBlock:(BOOL (^)(NSArray *eventsList))block;
{
    NSString *appId = [self.tracker applicationId];
    RL_DEBUG(appId, @"[Monitor] Uploading...");
    
    BOOL (^uploadBlock)(NSArray *eventsList) = [block copy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[BDAutoTrackMonitorStore sharedStore] dequeue:appId usingBlock:^BOOL(NSArray<BDAutoTrackMetrics *> * _Nonnull metricsList) {
            NSMutableArray *eventList = NSMutableArray.array;
            for (BDAutoTrackMetrics *metrics in metricsList) {
                id event = [metrics transformLogEvent];
                if (event) {
                    [eventList addObject:event];
                }
            }
            RL_DEBUG(appId, @"[Monitor] upload start...[%d]", [metricsList count]);
            BOOL result = uploadBlock(eventList.copy);
            RL_DEBUG(appId, @"[Monitor] upload %@...[%d]", result?@"success":@"failure",[metricsList count]);
            return result; 
        }];
    });
}



+ (instancetype)moduleWithTracker:(id<BDroneTracker>)tracker
{
    BDroneMonitor *monitor = [[BDroneMonitor alloc] init];
    monitor.tracker = tracker;
    [monitor commonInit];
    return monitor;
}

- (void)commonInit
{
    if (!self.tracker) {
        return;
    }
    NSString *name = [NSString stringWithFormat:@"volcengine.tracker.monitor.%@",[self.tracker applicationId]];
    monitorQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    onMonitorQueueTag = &onMonitorQueueTag;
    void *nonNullUnusedPointer = (__bridge void *)self;
    dispatch_queue_set_specific(monitorQueue, onMonitorQueueTag, nonNullUnusedPointer, NULL);
    
    presetAggregations = [NSMutableDictionary dictionary];
    
    collector = [[BDAutoTrackMetricsCollector alloc] initWithApplicationId:[self.tracker applicationId]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self async:^{
        [BDAutoTrackMonitorStore sharedStore];
    }];
    
}

- (BDAutoTrackMetricsCollector *)metricsCollector
{
    return collector;
}

- (void)onEnterBackground
{
    [self flush];
}


- (void)presetAggregation:(BDroneMonitorAggregation *)aggregation
               forMetrics:(NSString *)metric_
                 category:(NSString *)category_
{
    if (metric_.length == 0
        || category_.length == 0) {
        return;
    }
    NSString *metrics = [metric_ copy];
    NSString *category = [category_ copy];
    
    [self async:^{
        
        NSString *key = [NSString stringWithFormat:@"%@|%@", [category lowercaseString],[metrics lowercaseString]];
        [self->presetAggregations setValue:aggregation forKey:key];
            
    }];
}



- (void)async:(dispatch_block_t)block
{
    if (dispatch_get_specific(onMonitorQueueTag))
        block();
    else
        dispatch_async(monitorQueue, block);
}

- (void)trackMetrics:(NSString *)metrics_
               value:(NSNumber *)val_
            category:(NSString *)category_
          dimensions:(NSDictionary *)dimensions_
{
    if (metrics_.length == 0 || category_.length == 0) {
        return;
    }
    NSString *category = [category_ copy];
    NSString *metrics = [metrics_ copy];
    NSNumber *val = [val_ copy];
    NSDictionary *dimensions = [[NSDictionary alloc] initWithDictionary:dimensions_ copyItems:YES];
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    [self async:^{
        
        NSString *key = [NSString stringWithFormat:@"%@|%@", [category lowercaseString],[metrics lowercaseString]];
        BDroneMonitorAggregation *aggregation = aggregation = [self->presetAggregations objectForKey:key];
        [[self metricsCollector] trackMetrics:metrics value:val category:category dimensions:dimensions aggregation:aggregation time:current];
        
    }];
    
}

- (void)flush
{
    [self async:^{
        [[self metricsCollector] flush];
    }];
}



@end
