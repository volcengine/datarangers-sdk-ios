//
//  BDAutoTrack+Extension.m
//  RangersAppLog
//
//  Created by bytedance on 9/27/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Extension.h"
#import "BDAutoTrackerDefines.h"
#import "BDAutoTrack+Private.h"
#import <objc/runtime.h>


@interface BDTrackerEventBuilderImpl : NSObject<BDTrackerEventBuilder>

@property (nonatomic, weak) BDAutoTrack *tracker;

@property (nonatomic, copy) NSString *event;

@property (nonatomic, strong) NSMutableDictionary *parameters;

@property (nonatomic, strong) NSMutableSet *abtesingExperiments;

@end

@implementation BDTrackerEventBuilderImpl

- (id<BDTrackerEventBuilder>)addParameters:(NSDictionary<NSString *, id> *)parameters
{
    if ([NSJSONSerialization isValidJSONObject:parameters]) {
        if (!self.parameters) {
            self.parameters = [NSMutableDictionary dictionary];
        }
        [self.parameters addEntriesFromDictionary:[[NSMutableDictionary alloc] initWithDictionary:parameters copyItems:YES]];
    }
    return self;
}

- (nonnull id<BDTrackerEventBuilder>)addABTestingExperiments:(nonnull NSString *)vids {
    
    if ([vids isKindOfClass:NSString.class] && vids.length > 0) {
        if (!self.abtesingExperiments) {
            self.abtesingExperiments = [NSMutableSet set];
        }
        [self.abtesingExperiments addObjectsFromArray:[vids componentsSeparatedByString:@","]];
    }
    return self;
}

- (void)track {
    
    BDAutoTrackEventOption *option = [BDAutoTrackEventOption new];
    option.abtestingExperiments = [self.abtesingExperiments.allObjects componentsJoinedByString:@","];
    [self.tracker trackEvent:self.event parameters:self.parameters option:option];
    
}

@end


@implementation BDAutoTrack (Extension)

- (id<BDTrackerEventBuilder>)eventBuilder:(nonnull NSString *)event
{
    if (![event isKindOfClass:NSString.class] || event.length == 0) {
        return nil;
    }
    
    BDTrackerEventBuilderImpl *builder = [[BDTrackerEventBuilderImpl alloc] init];
    builder.tracker = self;
    builder.event = event;
    return builder;
}

- (void)trackEvent:(NSString *)event
        parameters:(NSDictionary *)parameters
            option:(BDAutoTrackEventOption *)option
{
    [self.eventGenerator trackEvent:event parameter:parameters options:option];
}

@end



