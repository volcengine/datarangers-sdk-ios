//
//  BDroneMonitorAgent.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDroneMonitorAgent.h"
#import "BDroneMonitorDefines.h"
#import "BDroneDefines.h"
#import "BDAutoTrack.h"

#import "BDAutoTrackBatchService.h"
#import "BDCommonEnumDefine.h"


#pragma mark - BDAutoTrackMonitorAggregation

@interface BDroneMonitorAggregation ()

@end


@implementation BDroneMonitorAggregation


+ (instancetype)aggregation
{
    return [BDroneMonitorAggregation new];
}

+ (instancetype)countAggregation
{
    BDroneMonitorAggregation *aggregation = [BDroneMonitorAggregation new];
    aggregation.aggregationType = MONITOR_AGGREGATION_TYPE_COUNT;
    return aggregation;
}

+ (instancetype)distributionAggregation:(NSArray<NSNumber *> *)intervals
{
    BDroneMonitorAggregation *aggregation = [BDroneMonitorAggregation new];
    aggregation.aggregationType = MONITOR_AGGREGATION_TYPE_COUNT_DISTRIBUTION;
    aggregation.intervals = intervals;
    return aggregation;
}
//预聚合指标字段
- (instancetype)addAggregateField:(NSArray<NSString *> *)fields
{
    self.fields = fields;
    return self;
}

@end





@interface BDUnrecognizedGuarder : NSObject
+ (instancetype)guarder;
- (void)guard;
@end

@implementation BDUnrecognizedGuarder
+ (instancetype)guarder
{
    static BDUnrecognizedGuarder *guarder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        guarder = [BDUnrecognizedGuarder new];
    });
    return guarder;
}
- (void)guard{};

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig = [BDUnrecognizedGuarder instanceMethodSignatureForSelector:@selector(guard)];
    return sig;
}


@end

@implementation BDroneMonitorAgent {
    
    NSObject<BDroneModule,BDroneMonitorTracker> *monitorTarget;
    
}

+ (instancetype)agentWithTracker:(id)tracker;
{
    BDroneMonitorAgent *agent = [BDroneMonitorAgent alloc];
    //dynamic init BDroneMonitor
    Class clz = NSClassFromString(@"BDroneMonitor");
    if (clz) {
        if ([clz.class respondsToSelector:@selector(moduleWithTracker:)]) {
            id monitor = [clz moduleWithTracker:tracker];
            if (monitor) {
                agent->monitorTarget = monitor;
            }
        }
    }
    return agent;
}

- (void)upload
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        return;
    }
    [self _upload];
}

- (void)onEnterForeground
{
    [self _upload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_upload
{
    id tracker = [self->monitorTarget tracker];
    id<BDroneModule,BDroneMonitorTracker> monitor = self->monitorTarget;
    if ([monitor respondsToSelector:@selector(uploadUsingBlock:)]) {
        [monitor uploadUsingBlock:^BOOL(NSArray * _Nonnull eventsList) {
            return [BDAutoTrackBatchService syncBatch:tracker withEvents:eventsList];
        }];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([monitorTarget respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([monitorTarget respondsToSelector:aSelector]) {
        return monitorTarget;
    }
    return [BDUnrecognizedGuarder guarder];
}

- (void)presetAggregation
{
    //event 调用
    [self presetAggregation:[BDroneMonitorAggregation countAggregation] forMetrics:BDroneTrackEventVolume category:BDroneTrackCategory];
    
    //上报延迟
    NSArray *delayDistributionIntervals = @[
        @(1*1000), //1s
        @(10*1000),//10s
        @(60*1000),//1min
        @(5*60*1000),//5min
        @(20*60*1000),//20min
        @(60*60*1000),//60min
        @(6*60*60*1000),//6h
    ];
    BDroneMonitorAggregation *aggregation = [BDroneMonitorAggregation distributionAggregation:delayDistributionIntervals];
    [aggregation addAggregateField:@[@"data_type"]];
    [self presetAggregation:aggregation forMetrics:BDroneUsageDataUploadDelay category:BDroneUsageCategory];

}


- (void)disable
{
    [self flush];
    self->monitorTarget = nil;
}


- (void)trackUrl:(NSURL *)url
            type:(BDAutoTrackRequestURLType)type
        response:(NSHTTPURLResponse *)response
        interval:(NSTimeInterval)interval
         success:(BOOL)success
           error:(NSError *)error
{
    BDroneMonitorMetricsName metricsName = [self metricsNameForType:type];
    if (!metricsName) {
        return;
    }
    if (!url) {
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(0) success:NO code:2001 properties:@{} underlyingError:error];
        return;
    }
    NSMutableDictionary *dimensions =  NSMutableDictionary.dictionary;
    NSString *formatedURL = [url.host stringByAppendingPathComponent:url.path];
    [dimensions setValue:formatedURL forKey:@"url"];
    if (error) {
        //网络错误
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(interval*1000) success:NO code:2003 properties:dimensions underlyingError:error];
        return;
    }
    if (error == nil && response == nil && !success) {
        //序列化错误
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(interval*1000) success:NO code:2002 properties:dimensions underlyingError:error];
        return;
    }
    
    NSUInteger statusCode = response.statusCode;
    [dimensions setValue:@(statusCode) forKey:@"status_code"];
    
    if (statusCode >= 400) {
        //服务端异常
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(interval*1000) success:NO code:2004 properties:dimensions underlyingError:error];
        return;
    }
    
    if (success) {
        //成功
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(interval*1000) success:success code:0 properties:dimensions underlyingError:error];
    } else {
        //服务端解析失败
        [self trackMetrics:metricsName category:BDroneNetworkCategory value:@(interval*1000) success:NO code:2006 properties:dimensions underlyingError:error];
    }
    
}




- (BDroneMonitorMetricsName)metricsNameForType:(BDAutoTrackRequestURLType)type
{
    switch (type) {
        case BDAutoTrackRequestURLSettings:             return BDroneNetworkLogSetting;
        case BDAutoTrackRequestURLABTest:               return BDroneNetworkABTest;
        case BDAutoTrackRequestURLRegister:             return BDroneNetworkDeviceRegistration;
        case BDAutoTrackRequestURLActivate:             return BDroneNetworkDeviceActivation;
        case BDAutoTrackRequestURLProfile:              return BDroneNetworkProfile;
        case BDAutoTrackRequestURLALinkLinkData:        return BDroneNetworkALinkDeepLink;
        case BDAutoTrackRequestURLALinkAttributionData: return BDroneNetworkALinkDeferredDeepLink;
        default:
            return nil;
    }
    return nil;
}
            


- (void)trackMetrics:(BDroneMonitorMetricsName)metrics
            category:(BDroneMonitorCategory)category
               value:(NSNumber *)val
             success:(BOOL)success
                code:(NSInteger)code
          properties:(NSDictionary *)properties
     underlyingError:(NSError *)error
{
    
    NSMutableDictionary *dimensions =  NSMutableDictionary.dictionary;
    if (properties) {
        [dimensions addEntriesFromDictionary:properties];
    }
    [dimensions setValue:success?@"1":@"0" forKey:@"dim_success"];
    if (!success) {
        [dimensions setValue:@(code) forKey:@"err_code"];
        if (error) {
            [dimensions setValue:@(error.code) forKey:@"err_underlying_code"];
            [dimensions setValue:error.localizedDescription forKey:@"err_message"];
        }
    }
    [self trackMetrics:metrics value:val category:category dimensions:dimensions];
}

- (void)trackEventCall
{
    [self trackMetrics:BDroneTrackEventVolume value:@(1) category:BDroneTrackCategory dimensions:nil];
}


@end
