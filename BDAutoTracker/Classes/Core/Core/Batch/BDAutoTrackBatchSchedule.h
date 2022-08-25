//
//  BDAutoTrackBatchSchedule.h
//  RangersAppLog
//
//  Created by bob on 2019/9/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 降级控制
@interface BDAutoTrackBatchSchedule : NSObject

/// use default value
@property (nonatomic, assign) NSInteger keepCount;
@property (nonatomic, assign) NSTimeInterval scheduleIntervalMin;
@property (nonatomic, assign) NSTimeInterval scheduleInterval;

- (instancetype)initWithAppID:(NSString *)appID;
- (BOOL)actionInSchedule;
- (void)scheduleWithHTTPCode:(NSInteger)code;

@end

NS_ASSUME_NONNULL_END
