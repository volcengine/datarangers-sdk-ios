//
//  BDAutoTrack+Extension.h
//  RangersAppLog
//
//  Created by bytedance on 9/27/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"

NS_ASSUME_NONNULL_BEGIN


@protocol BDTrackerEventBuilder <NSObject>

- (id<BDTrackerEventBuilder>)addParameters:(NSDictionary<NSString *, id> *)parameters;

- (id<BDTrackerEventBuilder>)addABTestingExperiments:(NSString *)vids;

- (void)track;

@end

@interface BDAutoTrack (Extension)

- (id<BDTrackerEventBuilder>)eventBuilder:(nonnull NSString *)event;

- (void)trackEvent:(NSString *)event
        parameters:(NSDictionary *)parameters
            option:(id)option;

@end

NS_ASSUME_NONNULL_END
