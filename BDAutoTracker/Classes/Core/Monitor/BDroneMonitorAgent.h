//
//  BDroneMonitorAgent.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDroneMonitorDefines.h"
#import "BDCommonEnumDefine.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDroneMonitorAgent : NSProxy<BDroneMonitorTracker>

+ (instancetype)agentWithTracker:(id)tracker;

- (void)presetAggregation;


- (void)trackMetrics:(BDroneMonitorMetricsName)metrics
            category:(BDroneMonitorCategory)category
               value:(NSNumber *)val
             success:(BOOL)success
                code:(NSInteger)code
          properties:(nullable NSDictionary *)properties
     underlyingError:(nullable NSError *)error;


- (void)trackUrl:(nullable NSURL *)url
            type:(BDAutoTrackRequestURLType)type
        response:(nullable NSHTTPURLResponse *)response
        interval:(NSTimeInterval)interval
         success:(BOOL)success
           error:(nullable NSError *)error;

- (void)trackEventCall;


- (void)disable;

- (void)upload;


@end

NS_ASSUME_NONNULL_END
