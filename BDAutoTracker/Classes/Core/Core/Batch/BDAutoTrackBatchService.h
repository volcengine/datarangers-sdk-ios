//
//  BDAutoTrackBatchService.h
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackBatchService : BDAutoTrackService

- (instancetype)initWithAppID:(NSString *)appID;
- (void)sendTrackDataFrom:(NSInteger)from;
- (void)sendTrackDataFrom:(NSInteger)from flushTimeInterval:(NSInteger)flushTimeInterval;

- (void)realtimeEventBatch;

+ (BOOL)syncBatch:(id)tracker withEvents:(NSArray *)events;

@end

FOUNDATION_EXTERN void bd_batchUpdateTimer(CFTimeInterval interval, BOOL skipLaunch, NSString *appID);
FOUNDATION_EXTERN BOOL bd_batchIsEventInBlockList(NSString *event, NSString *appID);

NS_ASSUME_NONNULL_END
