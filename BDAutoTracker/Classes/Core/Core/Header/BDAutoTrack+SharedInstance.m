//
//  BDAutoTrackHolder.m
//  RangersAppLog
//
//  Created by bob on 2019/10/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"
#import "BDAutoTrack+SharedInstance.h"
#import "BDTrackerCoreConstants.h"

#import "BDAutoTrack+Special.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDAutoTrackLocalConfigService.h"

static BDAutoTrack *track = nil;
static BDAutoTrackCustomHeaderBlock storedCustomHeader = nil;
static BDAutoTrackRequestURLBlock storedRequestURLBlock = nil;
static BDAutoTrackRequestHostBlock storedRequestHostBlock = nil;

@implementation BDAutoTrack (SharedInstance)

#pragma mark - 初始化与启动单例
+ (void)startTrackWithConfig:(BDAutoTrackConfig *)config {
    [BDAutoTrack sharedTrackWithConfig:config];
    [BDAutoTrack startTrack];
}

+ (void)sharedTrackWithConfig:(BDAutoTrackConfig *)config {
    track = [BDAutoTrack trackWithConfig:config];
    [track setCustomHeaderBlock:storedCustomHeader];
    [track setRequestURLBlock:storedRequestURLBlock];
    [track setRequestHostBlock:storedRequestHostBlock];
}

+ (void)startTrack {
    [track startTrack];
}

+ (instancetype)sharedTrack {
    return track;
}

#pragma mark - class property
+ (NSString *)appID {
    return track.appID;
}

+ (NSString *)rangersDeviceID {
    return track.rangersDeviceID;
}

+ (NSString *)installID {
    return track.installID;
}

+ (NSString *)ssID {
    return track.ssID;
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat:@"%@", @(BDAutoTrackerSDKVersion)];
}

+ (NSString *)userUniqueID {
    return track.userUniqueID;
}

#pragma mark - public method
+ (void)setUserAgent:(NSString *)userAgent {
    [track setUserAgent:userAgent];
}

+ (BOOL)setCurrentUserUniqueID:(NSString *)uniqueID {
    return [track setCurrentUserUniqueID:uniqueID];
}

+ (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID withType:(nullable NSString *)type
{
    return [track setCurrentUserUniqueID:uniqueID withType:type];
}

+ (void)clearUserUniqueID {
    [track clearUserUniqueID];
}

+ (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(NSString *)registeringUserUniqueID {
    return [track sendRegisterRequestWithRegisteringUserUniqueID:registeringUserUniqueID];
}

+ (BOOL)sendRegisterRequest APPLOG_API_AVALIABLE(5.6.3) {
    return [track sendRegisterRequest];
}

+ (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor {
    [track setServiceVendor:serviceVendor];
}

+ (void)setRequestURLBlock:(BDAutoTrackRequestURLBlock)requestURLBlock {
    storedRequestURLBlock = [requestURLBlock copy];
    [track setRequestURLBlock:requestURLBlock];
}

+ (void)setAppRegion:(NSString *)appRegion {
    [track setAppRegion:appRegion];
}

+ (void)setAppTouchPoint:(NSString *)appTouchPoint {
    [track setAppTouchPoint:appTouchPoint];
}

+ (void)setRequestHostBlock:(BDAutoTrackRequestHostBlock)requestHostBlock {
    storedRequestHostBlock = [requestHostBlock copy];
    [track setRequestHostBlock:requestHostBlock];
}

+ (void)setAppLauguage:(NSString *)appLauguage {
    [track setAppLauguage:appLauguage];
}

+ (void)setCustomHeaderValue:(id)value forKey:(NSString *)key {
    [track setCustomHeaderValue:value forKey:key];
}

+ (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    [track setCustomHeaderWithDictionary:dictionary];
}

+ (void)removeCustomHeaderValueForKey:(NSString *)key {
    [track removeCustomHeaderValueForKey:key];
}

+ (void)setCustomHeaderBlock:(BDAutoTrackCustomHeaderBlock)customHeaderBlock {
    storedCustomHeader = [customHeaderBlock copy];
    [track setCustomHeaderBlock:customHeaderBlock];
}

+ (BOOL)eventV3:(NSString *)event params:(NSDictionary *)params {
    if (track == nil) {
        return NO;
    }
    
    return [track eventV3:event params:params];
}

+ (id)ABTestConfigValueForKey:(NSString *)key defaultValue:(id)defaultValue {
    if (track == nil) {
        return defaultValue;
    }
    
    return [track ABTestConfigValueForKey:key defaultValue:defaultValue];
}

+ (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue {
    return [track ABTestConfigValueSyncForKey:key defaultValue:defaultValue];
}

+ (void)setExternalABVersion:(NSString *)versions {
    [track setExternalABVersion:versions];
}

+ (NSString *)abVids {
    return [track abVids];
}

+ (NSString *)allAbVids {
    return [track allAbVids];
}

+ (NSDictionary *)allABTestConfigs {
    return [track allABTestConfigs];
}

+ (NSDictionary *)allABTestConfigs2 {
    return [track allABTestConfigs2];
}

+ (nullable NSString *)abVidsSync {
    return [[self sharedTrack] abVidsSync];
}

+ (nullable NSString *)allAbVidsSync {
    return [[self sharedTrack] allAbVidsSync];
}

+ (nullable NSDictionary *)allABTestConfigsSync {
    return [[self sharedTrack] allABTestConfigsSync];
}

+ (void)pullABTestConfigs {
    [[self sharedTrack] pullABTestConfigs];
}

+ (void)flush {
    [track flushWithTimeInterval:10];
}

#pragma mark - ALink
+ (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate {
    return [track setALinkRoutingDelegate:ALinkRoutingDelegate];
}

+ (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    return [track continueALinkActivityWithURL:ALinkURL];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma mark - Special

@implementation BDAutoTrack (SharedSpecial)


+ (BOOL)eventV3:(NSString *)event
         params:(NSDictionary *)params
  specialParams:(NSDictionary *)specialParams {

    return [track eventV3:event params:params specialParams:specialParams];
}

+ (BOOL)customEvent:(NSString *)category params:(NSDictionary *)params {
    return [track customEvent:category params:params];
}

@end

#pragma clang diagnostic pop
