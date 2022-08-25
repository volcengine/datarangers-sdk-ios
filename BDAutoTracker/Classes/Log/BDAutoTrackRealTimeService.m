//
//  BDAutoTrackRealTimeService.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRealTimeService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackKeepRequest.h"
#import "BDAutoTrackTimer.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"

static NSString *const kBDAutoTrackRealTimeServiceTimer    = @"kBDAutoTrackRealTimeServiceTimer";

@interface BDAutoTrackRealTimeService ()

@property (nonatomic, strong) BDAutoTrackKeepRequest *request;
@property (nonatomic, copy) NSString *timerName;
@property (nonatomic, strong) dispatch_queue_t sendingQueue;

@end

@implementation BDAutoTrackRealTimeService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameLog;
        self.request = nil;
        self.timerName = [kBDAutoTrackRealTimeServiceTimer stringByAppendingFormat:@"_%@",appID];
        NSString *queueName = [NSString stringWithFormat:@"com.applog.debuglog_%@",appID];
        self.sendingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)registerService {
    [super registerService];
    [self start];
}

- (void)unregisterService {
    [super unregisterService];
    [self stopTimer];
}

- (void)start {
    BDAutoTrackKeepRequest *request = self.request;
    if (request) {
        request.keep = NO;
    }
    request = [[BDAutoTrackKeepRequest alloc] initWithService:self type:BDAutoTrackRequestURLSimulatorLog];
    self.request = request;
    [self startTimer];
}

- (void)startTimer {
    BDAutoTrackWeakSelf;
    dispatch_block_t action = ^{
        BDAutoTrackStrongSelf;
        BDAutoTrackKeepRequest *request = self.request;
        if (request) {
            request.parameters = @{};
            [request startRequestWithRetry:0];
        }
    };
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:self.timerName
                                                         timeInterval:1
                                                                queue:self.sendingQueue
                                                              repeats:YES
                                                               action:action];
}

- (void)stopTimer {
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:self.timerName];
    self.request.keep = NO;
    self.request = nil;
}

- (void)sendEvent:(NSDictionary *)event key:(NSString *)key {
    if (![event isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (event.count < 1) {
        return;
    }
    if (![key isKindOfClass:[NSString class]]) {
        return;
    }
    if ([key isEqualToString:BDAutoTrackTableUIEvent] || [key isEqualToString:BDAutoTrackTableProfile]) {
        key = BDAutoTrackTableEventV3;
    }
    if (![NSJSONSerialization isValidJSONObject:event]) {
        return;
    }
    NSDictionary *data = @{key:@[event]};
    BDAutoTrackWeakSelf;
    dispatch_async(self.sendingQueue, ^{
        BDAutoTrackStrongSelf;
        self.request.parameters = data;
        [self.request startRequestWithRetry:0];
    });
}

@end
