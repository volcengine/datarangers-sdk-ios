//
//  BDAutoTrackLocalConfigService.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackDefaults.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackServiceCenter.h"

static NSString * const kBDAutoTrackEventFilterEnabled = @"kBDAutoTrackEventFilterEnabled";

@interface BDAutoTrackLocalConfigService () {
    
}

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, strong) NSMutableDictionary *customData;

@end

@implementation BDAutoTrackLocalConfigService

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config {
    self = [super initWithAppID:config.appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameSettings;
        self.appName = config.appName;
        self.channel = config.channel;
        self.serviceVendor = config.serviceVendor;
        self.logNeedEncrypt = config.logNeedEncrypt;
        self.autoFetchSettings = config.autoFetchSettings;
        self.abTestEnabled = config.abEnable;
        
        // 设置所有埋点上报总开关
        self.trackEventEnabled = config.trackEventEnabled;
        self.autoTrackEnabled = config.autoTrackEnabled;
        self.screenOrientationEnabled = config.screenOrientationEnabled;
        self.trackGPSLocationEnabled = config.trackGPSLocationEnabled;
        self.trackPageLeaveEnabled = config.trackPageLeaveEnabled;
        
        self.customHeaderBlock = nil;
        self.requestURLBlock = nil;
        self.requestHostBlock = nil;
        self.pickerHost = nil;
        
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        self.defaults = defaults;
        self.userAgent = [defaults stringValueForKey:kBDAutoTrackConfigUserAgent];
        self.appLauguage = [defaults stringValueForKey:kBDAutoTrackConfigAppLanguage];
        self.appRegion = [defaults stringValueForKey:kBDAutoTrackConfigAppRegion];
        self.appTouchPoint = [defaults stringValueForKey:kBDAutoTrackConfigAppTouchPoint];
        self.eventFilterEnabled = [defaults boolValueForKey:kBDAutoTrackEventFilterEnabled];
        self.customData = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryValueForKey:kBDAutoTrackCustom]
                                                                copyItems:YES];
    }

    return self;
}

- (void)impl_setCustomHeaderValue:(id)value forKey:(NSString *)key {
    if ([key isKindOfClass:[NSString class]]) {
        @synchronized (self.customData) {
            [self.customData setValue:value forKey:key];
            [self.defaults setDefaultValue:self.customData forKey:kBDAutoTrackCustom];
        }
    }
}

- (NSMutableDictionary *)currentCustomData
{
    NSMutableDictionary *custom = [NSMutableDictionary dictionary];
    @synchronized (self.customData) {
        [custom addEntriesFromDictionary:[self.customData copy]];
    }
    return custom;
}

- (void)setCustomHeaderValue:(id)value forKey:(NSString *)key {
    [self impl_setCustomHeaderValue:value forKey:key];
    [self.defaults saveDataToFile];
}

- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    @try {
        if ([NSJSONSerialization isValidJSONObject:dictionary]) {
            for (NSString *key in dictionary) {
                [self impl_setCustomHeaderValue:dictionary[key] forKey:key];
            }
            [self.defaults saveDataToFile];
        }
    } @catch(NSException *e) {
        
    }
    
}

- (void)removeCustomHeaderValueForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    @synchronized (self.customData) {
        [self.customData removeObjectForKey:key];
        [self.defaults setDefaultValue:self.customData forKey:kBDAutoTrackCustom];
        [self.defaults saveDataToFile];
    }
}

- (void)clearCustomHeader {
    @synchronized (self.customData) {
        [self.customData removeAllObjects];
        [self.defaults setDefaultValue:nil forKey:kBDAutoTrackCustom];
        [self.defaults saveDataToFile];
    }

}

- (void)saveEventFilterEnabled:(BOOL)enabled {
    self.eventFilterEnabled = enabled;
    BDAutoTrackDefaults *defaults = self.defaults;
    [defaults setValue:@(enabled) forKey:kBDAutoTrackEventFilterEnabled];
}

- (void)saveAppRegion:(NSString *)appRegion {
    self.appRegion = appRegion;
    BDAutoTrackDefaults *defaults = self.defaults;
    [defaults setValue:appRegion forKey:kBDAutoTrackConfigAppRegion];
}

- (void)saveAppTouchPoint:(NSString *)appTouchPoint {
    self.appTouchPoint = appTouchPoint;
    BDAutoTrackDefaults *defaults = self.defaults;
    [defaults setValue:appTouchPoint forKey:kBDAutoTrackConfigAppTouchPoint];
}

- (void)saveAppLauguage:(NSString *)appLauguage {
    self.appLauguage = appLauguage;
    BDAutoTrackDefaults *defaults = self.defaults;
    [defaults setValue:appLauguage forKey:kBDAutoTrackConfigAppLanguage];
}

- (void)saveUserAgent:(NSString *)userAgent {
    self.userAgent = userAgent;
    BDAutoTrackDefaults *defaults = self.defaults;
    [defaults setValue:userAgent forKey:kBDAutoTrackConfigUserAgent];
}

/// 1. local config字段
/// 2. custom 字段
- (void)addSettingParameters:(NSMutableDictionary *)result {
    /* 添加本地设置字段 */
    [result setValue:self.appID forKey:kBDAutoTrackAPPID];
    [result setValue:self.appName forKey:kBDAutoTrackAPPName];
    [result setValue:self.channel forKey:kBDAutoTrackChannel];

    NSString *appLauguage = self.appLauguage ?: bd_device_currentLanguage();
    [result setValue:appLauguage forKey:kBDAutoTrackAppLanguage];
    NSString *appRegion = self.appRegion ?: bd_device_currentRegion();
    [result setValue:appRegion forKey:kBDAutoTrackAppRegion];
    NSString *ua = self.userAgent ?: bd_sandbox_userAgent();
    [result setValue:ua forKey:kBDAutoTrackUserAgent];
    
    /* 添加custom字段 */
    NSMutableDictionary *custom = [self currentCustomData];
    
    BDAutoTrackCustomHeaderBlock customHeaderBlock = self.customHeaderBlock;
    
    if (customHeaderBlock) {
        NSDictionary *userCustom = [[NSDictionary alloc] initWithDictionary:customHeaderBlock() copyItems:YES];
        [custom addEntriesFromDictionary:userCustom];
    }
    
    // touchPoint也算custom字段
    NSString *touchPoint = self.appTouchPoint;
    if (touchPoint) {
        [custom setValue:touchPoint forKey:kBDAutoTrackTouchPoint];
    }
    
    if (custom.count > 0) {
        [result setValue:custom forKey:kBDAutoTrackCustom];
    }
}

@end

BDAutoTrackLocalConfigService *_Nullable bd_settingsServiceForAppID(NSString *appID) {
    BDAutoTrackLocalConfigService *settings = (BDAutoTrackLocalConfigService *)bd_standardServices(BDAutoTrackServiceNameSettings, appID);
    if ([settings isKindOfClass:[BDAutoTrackLocalConfigService class]]) {
        return settings;
    }
    
    return nil;
}

void bd_addSettingParameters(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(appID);
    if (settings) {
        [settings addSettingParameters:result];
    }
}
