//
//  BDAutoTrackBatchSchedule.m
//  RangersAppLog
//
//  Created by bob on 2019/9/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBatchSchedule.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackDefaults.h"

/// 正常情况下1分钟1条， 2分钟内限制10条（切后台可能上报比较多一点）
/// 如果服务端返回5xx后，每个间隔1条，1分钟 -> 2分钟 -> 4分钟 -> 8分钟 -> 16分钟
/// 最大间隔就16分钟，不会降级到32分钟
/// 如果返回200后,时间间隔先恢复，8分钟 -> 4分钟 -> 2分钟
/// 2分钟之内最多发1条->2条->3条->，这样慢速增长

static const NSTimeInterval    kDefaultScheduleInterval     = 60;
static const NSTimeInterval    kBatchSendingIntervalMax = 16 * 60;

static const NSInteger         kDefaultMaxSendingTimes      = 10;
static const NSInteger         kDefaultKeepCount            = 5;
static const NSTimeInterval    kMaxKeepInterval             = 30 * 60;
static const NSTimeInterval    kDescendMaxTime =  3 * 60 * 60;
static NSString *const kAppLogDescendTime = @"kAppLogDescendTime";
static NSString *const kAppLogDescendInterval = @"kAppLogDescendInterval";

@interface BDAutoTrackBatchSchedule ()

@property (nonatomic, assign) NSTimeInterval modifyTimeStamp;
@property (nonatomic, assign) NSInteger sendingTimes;       /// 接口已经发送的次数
@property (nonatomic, assign) NSInteger maxTSendingTimes;   /// 接口interval内最大可发送的次数
@property (nonatomic, assign) NSInteger successCount;
@property (nonatomic, copy) NSString *appID;
@end

@implementation BDAutoTrackBatchSchedule

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keepCount = kDefaultKeepCount;
        self.maxTSendingTimes = kDefaultMaxSendingTimes;
        self.modifyTimeStamp = CFAbsoluteTimeGetCurrent();
        self.scheduleInterval = kDefaultScheduleInterval;
        self.scheduleIntervalMin = kDefaultScheduleInterval;
        self.sendingTimes = 0;
        self.successCount = 0;
    }

    return self;
}

- (instancetype)initWithAppID:(NSString *)appID {
    self = [self init];
    if (self) {
        self.appID = appID;
        CFTimeInterval current = CFAbsoluteTimeGetCurrent();
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
        CFTimeInterval last = [defaults doubleValueForKey:kAppLogDescendTime];
        if (current - last < kDescendMaxTime) {
            self.scheduleInterval = MAX([defaults doubleValueForKey:kAppLogDescendInterval], self.scheduleInterval);
            self.maxTSendingTimes = 1;
        }
    }

    return self;
}

- (BOOL)actionInSchedule {
    CFTimeInterval current = CFAbsoluteTimeGetCurrent();

    if (current - self.modifyTimeStamp > self.scheduleInterval) {
        self.sendingTimes = 0;
        self.modifyTimeStamp = current;
    }

    if (self.sendingTimes >= self.maxTSendingTimes) {
        return NO;
    }

    self.sendingTimes++;

    return YES;
}

- (void)scheduleWithHTTPCode:(NSInteger)code {
    if (code == 200) {
        [self ascendCount];
    } else if (code > 499 && code < 600) {
        [self descendCount];
    }
}

- (void)descendCount {
    self.successCount = 0;
    self.maxTSendingTimes = 1;
    self.scheduleInterval =  MIN(kBatchSendingIntervalMax, self.scheduleInterval * 2);

    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [defaults setValue:@(self.scheduleInterval) forKey:kAppLogDescendInterval];
    [defaults setValue:@(CFAbsoluteTimeGetCurrent()) forKey:kAppLogDescendTime];
}

- (void)ascendCount {
    if (self.maxTSendingTimes >= kDefaultMaxSendingTimes) {
        return;
    }

    if (self.successCount >= self.keepCount) {
        self.successCount = 0;
        self.scheduleInterval /= 2;
        if (self.scheduleInterval < self.scheduleIntervalMin) {
            self.scheduleInterval = self.scheduleIntervalMin;
            self.maxTSendingTimes++;
        }
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        [defaults setValue:@(self.scheduleInterval) forKey:kAppLogDescendInterval];
        return;
    }

    if (self.successCount * self.scheduleInterval >= kMaxKeepInterval) {
        self.successCount = 0;
        self.scheduleInterval /= 2;
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        [defaults setValue:@(self.scheduleInterval) forKey:kAppLogDescendInterval];
        return;
    }

    self.successCount++;
}

@end
