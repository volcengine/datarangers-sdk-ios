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
#import "BDAutoTrackEventCheck.h"
#import "BDAutoTrack+Private.h"
#import "NSDictionary+VETyped.h"

static NSString * const kBDAutoTrackEventFilterEnabled = @"kBDAutoTrackEventFilterEnabled";
static NSString * const kBDAutoTrackExternalVids       = @"kBDAutoTrackExternalVids";     // Array
static NSString * const kBDAutoTrackTimeSyncStorageKey = @"kTimeSyncStorageKey";
static NSString * const kBDAutoTrackDESKey = @"0C25A27B28333530D11E2E56";

@interface BDAutoTrackLocalConfigService () {
    
}

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, strong) NSMutableDictionary *customData;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (atomic, copy, nullable) NSString *syncUserUniqueID;
@property (atomic, copy, nullable) NSString *syncUserUniqueIDType;
@property (atomic, copy, nullable) NSString *ssID;

@property (atomic, strong) NSDictionary *serverTimeDicts;


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
        self.showDebugLog = config.showDebugLog;
        
        self.trackEventEnabled = config.trackEventEnabled;
        self.autoTrackEnabled = config.autoTrackEnabled;
        self.screenOrientationEnabled = config.screenOrientationEnabled;
        self.trackGPSLocationEnabled = config.trackGPSLocationEnabled;
        self.trackPageEnabled = config.autoTrackEventType & BDAutoTrackDataTypePage;
        self.trackPageClickEnabled = config.autoTrackEventType & BDAutoTrackDataTypeClick;
        self.trackPageLeaveEnabled = config.autoTrackEventType & BDAutoTrackDataTypePageLeave;
        
        self.customHeaderBlock = nil;
        self.requestURLBlock = nil;
        self.requestHostBlock = nil;
        self.commonParamtersBlock = nil;
        self.pickerHost = nil;
        
        self.requestAdvertisingURLBlock = nil;
        self.requestAdvertisingHostBlock = nil;
        
        BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        self.defaults = defaults;
        self.userAgent = [defaults stringValueForKey:kBDAutoTrackConfigUserAgent];
        self.appLauguage = [defaults stringValueForKey:kBDAutoTrackConfigAppLanguage];
        self.appRegion = [defaults stringValueForKey:kBDAutoTrackConfigAppRegion];
        self.appTouchPoint = [defaults stringValueForKey:kBDAutoTrackConfigAppTouchPoint];
        
        [self loadUser:defaults];
        
        self.eventFilterEnabled = [defaults boolValueForKey:kBDAutoTrackEventFilterEnabled];
        self.customData = [NSMutableDictionary dictionary];
        self.serverTimeDicts = [defaults objectForKey:kBDAutoTrackTimeSyncStorageKey];
        
        NSString *queueName = [NSString stringWithFormat:@"com.applog.localconfig_%@", config.appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        [self syncUserParameter];
    }

    return self;
}

- (void)impl_setCustomHeaderValue:(id)value forKey:(NSString *)key {
    if ([key isKindOfClass:[NSString class]]) {
        @synchronized (self.customData) {
            [self.customData setValue:value forKey:key];
        }
    }
}


- (void)updateUser:(NSString *)uuid
              type:(NSString *)type
              ssid:(NSString *)ssid
{
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    RL_INFO(tracker, @"User", @"update User %@:%@:%@", uuid, type, ssid);
    NSString *originalUUID = self.syncUserUniqueID;
   
    self.syncUserUniqueID = uuid;
    self.syncUserUniqueIDType = type;
    
    BOOL isUUIDChanged = YES;
    if (originalUUID == nil && uuid == nil) {
        isUUIDChanged = NO;
    } else if (originalUUID == nil || uuid == nil) {
        isUUIDChanged = YES;
    } else {
        isUUIDChanged = ![uuid isEqualToString:originalUUID];
    }
    
    if (!isUUIDChanged && ssid.length == 0) {
    } else {
        self.ssID = ssid;
    }
    
    [self syncUserParameter];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self saveUser];
    });
}

- (void)syncUserParameter
{
    [[BDAutoTrack trackWithAppID:self.appID].eventGenerator addEventParameter:@{
        kBDAutoTrackEventUserID: self.syncUserUniqueID ?: [NSNull null],
        kBDAutoTrackEventUserIDType: self.syncUserUniqueIDType?:[NSNull null],
        kBDAutoTrackSSID: self.ssID ?: @""
    }];
}

- (void)updateServerTime:(NSDictionary *)responseDict {
    long long interval = [responseDict vetyped_longlongValueForKey:kBDAutoTrackServerTime];
    if (interval > 0) {
        NSDictionary *serverTimeDicts = @{kBDAutoTrackServerTime: @(interval),
                                        kBDAutoTrackLocalTime: @((long long)(bd_currentIntervalValue()))};
        self.serverTimeDicts = serverTimeDicts;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.defaults setValue:serverTimeDicts forKey:kBDAutoTrackTimeSyncStorageKey];
        });
    }
}

- (NSDictionary *)serverTime {
    if (![self.serverTimeDicts isKindOfClass:[NSDictionary class]]) {
        long long interval = (long long)bd_currentIntervalValue();
        return @{kBDAutoTrackServerTime: @(interval),
                          kBDAutoTrackLocalTime: @(interval)};
    }
    return self.serverTimeDicts;
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
    }
}

- (void)clearCustomHeader {
    @synchronized (self.customData) {
        [self.customData removeAllObjects];
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

- (void)saveUser
{
    BDAutoTrackDefaults *defaults = self.defaults;
    
    NSError *error;
    NSString *uuid = [self.syncUserUniqueID copy];
    uuid = bd_ecs_encode(uuid, kBDAutoTrackDESKey, &error);
    if (!error) {
        [defaults setValue:nil forKey:kBDAutoTrackConfigUserUniqueID];
        [defaults setValue:uuid forKey:kBDAutoTrackConfigUserUniqueIDEncode];
    } else {
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
        RL_ERROR(tracker, @"User", @"encode uuid failed: ", error.userInfo.description);
        
        [defaults setValue:self.syncUserUniqueID forKey:kBDAutoTrackConfigUserUniqueID];
        [defaults setValue:nil forKey:kBDAutoTrackConfigUserUniqueIDEncode];
    }
    
    [defaults setValue:self.syncUserUniqueIDType forKey:kBDAutoTrackConfigUserUniqueIDType];
    [defaults setValue:self.ssID forKey:kBDAutoTrackConfigSSID];
    [defaults saveDataToFile];
}

- (void)loadUser:(BDAutoTrackDefaults *)defaults
{
    NSString *uuidEncode = [defaults stringValueForKey:kBDAutoTrackConfigUserUniqueIDEncode];
    if (uuidEncode && uuidEncode.length > 0) {
        NSError *error;
        NSString *uuid = bd_ecs_decode(uuidEncode, kBDAutoTrackDESKey, &error);
        if (!error) {
            self.syncUserUniqueID = uuid;
        } else {
            self.syncUserUniqueID = @"";
            
            BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
            RL_ERROR(tracker, @"User", @"decode uuid failed: ", error.userInfo.description);
        }
    } else {
        self.syncUserUniqueID = [defaults stringValueForKey:kBDAutoTrackConfigUserUniqueID];
    }
    
    self.syncUserUniqueIDType = [defaults stringValueForKey:kBDAutoTrackConfigUserUniqueIDType];
    self.ssID = [defaults stringValueForKey:kBDAutoTrackConfigSSID];
}

- (void)addSettingParameters:(NSMutableDictionary *)result {
    [result setValue:self.appID forKey:kBDAutoTrackAPPID];
    [result setValue:self.appName forKey:kBDAutoTrackAPPName];
    [result setValue:self.channel forKey:kBDAutoTrackChannel];

    [result setValue:self.syncUserUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
    [result setValue:self.syncUserUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
    
    NSString *appLauguage = self.appLauguage ?: bd_device_currentLanguage();
    [result setValue:appLauguage forKey:kBDAutoTrackAppLanguage];
    NSString *appRegion = self.appRegion ?: bd_device_currentRegion();
    [result setValue:appRegion forKey:kBDAutoTrackAppRegion];
    NSString *ua = self.userAgent ?: bd_sandbox_userAgent();
    [result setValue:ua forKey:kBDAutoTrackUserAgent];
    
    NSMutableDictionary *custom = [self currentCustomData];
    
    BDAutoTrackCustomHeaderBlock customHeaderBlock = self.customHeaderBlock;
    
    if (customHeaderBlock) {
        NSDictionary *userCustom = [[NSDictionary alloc] initWithDictionary:customHeaderBlock() copyItems:YES];
        [custom addEntriesFromDictionary:userCustom];
        
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
        if (tracker != nil && self.showDebugLog) {
            bd_checkCustomDictionary(tracker, userCustom);
        }
    }
    
    NSString *touchPoint = self.appTouchPoint;
    if (touchPoint) {
        [custom setValue:touchPoint forKey:kBDAutoTrackTouchPoint];
    }
    
    if (custom.count > 0) {
        [result setValue:custom forKey:kBDAutoTrackCustom];
    }
}

@end

void bd_addSettingParameters(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = [BDAutoTrack trackWithAppID:appID].localConfig;
    if (settings) {
        [settings addSettingParameters:result];
    }
}
