//
//  BDAutoTrackMonitorStore.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackMetrics;
@interface BDAutoTrackMonitorStore : NSObject

+ (instancetype)sharedStore;

- (void)enqueue:(NSArray<BDAutoTrackMetrics *> *)metricsList;

- (void)dequeue:(NSString *)appId usingBlock:(BOOL (^)(NSArray<BDAutoTrackMetrics *> *metricsList))block;


@end

NS_ASSUME_NONNULL_END
