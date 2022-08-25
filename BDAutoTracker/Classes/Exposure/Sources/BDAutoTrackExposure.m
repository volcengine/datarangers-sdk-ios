//
//  BDAutoTrackExposure.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/31.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackExposure.h"
#import "BDAutoTrackExposureManager.h"
#import "RangersLog.h"
#import <objc/runtime.h>

@implementation BDViewExposureData

+ (instancetype)event:(nullable NSString *)eventName
           properties:(nullable NSDictionary *)dicationay
               config:(nullable BDViewExposureConfig *)config
{
    BDViewExposureData *data = [BDViewExposureData new];
    data.eventName = [eventName copy];
    data.properties = [dicationay mutableCopy];
    data.config = config;
    return data;
}

- (BOOL)isEqual:(BDViewExposureData *)object
{
    if (![object isKindOfClass:BDViewExposureData.class]) {
        return NO;
    }
    if ([self.eventName isEqualToString:object.eventName]) {
        
        if (self.properties == nil && object.properties == nil) {
            return YES;
        }
        if (self.properties && object.properties
            && [self.properties isEqualToDictionary:object.properties]) {
            return YES;
        }
        return NO;
    }
    return NO;
}


- (NSString *)description
{
    NSString *eventName = self.eventName?:@"";
    NSString *prop_str = @"";
    if (self.properties && [NSJSONSerialization isValidJSONObject:self.properties]) {
        prop_str = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self.properties options:0 error:nil] encoding:NSUTF8StringEncoding];
    }
    return [NSString stringWithFormat:@"[event:%@]%@",eventName,prop_str];
}

@end


@interface BDViewExposureConfig ()

@property (nonatomic, assign) CGFloat areaRatio;

@property (nonatomic, copy) NSNumber *visualDiagnosisVal;

@end

@implementation BDViewExposureConfig

+ (instancetype)defaultConfig
{
    BDViewExposureConfig * config = [BDViewExposureConfig new];
    config.areaRatio = -1;
    return config;
}

+ (instancetype)globalDefaultConfig
{
    BDViewExposureConfig * config = [BDViewExposureConfig new];
    [config enableVisualDiagnosis:NO];
    [config areaRatio:0];
    return config;
}

- (instancetype)enableVisualDiagnosis:(BOOL)enable
{
    self.visualDiagnosisVal = @(enable);
    return self;;
}

- (instancetype)areaRatio:(CGFloat)radio
{
    self.areaRatio = radio;
    return self;
}

- (BOOL)visualDiagnosisEnabled;
{
    return [self.visualDiagnosisVal boolValue];
}

- (void)apply:(BDViewExposureConfig *)global
{
    if (self.areaRatio < 0) {
        self.areaRatio = global.areaRatio;
    }
    if (!self.visualDiagnosisVal) {
        self.visualDiagnosisVal = global.visualDiagnosisVal;
    }
}

@end

@implementation BDAutoTrack (BDTViewExposure)

- (void)observeViewExposure:(id)view
                   withData:(BDViewExposureData *)data
{
    if (!view) {
        return;
    }
    if (![view isKindOfClass:UIView.class]) {
        RL_WARN(self.appID, @"[Exposure] Observed an %@ object, expecting a UIView", NSStringFromClass([view class]));
        return;
    }
    [[BDAutoTrackExposureManager sharedInstance] observe:view with:data forTracker:self];
}

- (void)disposeViewExposure:(id)view
{
    if (!view) {
        return;
    }
    [[BDAutoTrackExposureManager sharedInstance] remove:view forTracker:self];
}

@end




@implementation BDAutoTrackConfig (BDTViewExposure)


- (void)setExposureEnabled:(BOOL)exposureEnabled
{
    objc_setAssociatedObject(self, @selector(exposureEnabled), @(exposureEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)exposureEnabled
{
    id val = objc_getAssociatedObject(self, @selector(exposureEnabled));
    if (!val) {
        return YES;
    }
    return [val boolValue];
}

- (void)setExposureConfig:(BDViewExposureConfig *)exposureConfig
{
    objc_setAssociatedObject(self, @selector(exposureConfig), exposureConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDViewExposureConfig *)exposureConfig
{
    
    BDViewExposureConfig *config = objc_getAssociatedObject(self, @selector(exposureConfig));
    if (!config) {
        config = [BDViewExposureConfig globalDefaultConfig];
        [self setExposureConfig:config];
    }
    return config;
}

@end
