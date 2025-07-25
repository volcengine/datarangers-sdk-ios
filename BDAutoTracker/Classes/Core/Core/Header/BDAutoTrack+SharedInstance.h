//
//  BDAutoTrack+SharedInstance.h
//  Pods
//
//  Created by 朱元清 on 2020/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN
#pragma mark - SharedInstance

@interface BDAutoTrack (SharedInstance)

@property (class, nonatomic, copy, readonly) NSString *sdkVersion APPLOG_API_DEPRECATED_WITH_REPLACEMENT("SDKVersion");

@property (class, nonatomic, copy, readonly, nullable) NSString *rangersDeviceID;

@property (class, nonatomic, copy, readonly, nullable) NSString *installID;

@property (class, nonatomic, copy, readonly, nullable) NSString *ssID;

@property (class, nonatomic, copy, readonly, nullable) NSString *userUniqueID;

@property (class, nonatomic, copy, readonly) NSString *appID;

#pragma mark - 初始化与启动单例

+ (void)startTrackWithConfig:(BDAutoTrackConfig *)config;

+ (void)sharedTrackWithConfig:(BDAutoTrackConfig *)config;

+ (void)startTrack;

+ (instancetype)sharedTrack;

#pragma mark -

+ (void)setUserAgent:(nullable NSString *)userAgent;

+ (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID;

+ (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID withType:(nullable NSString *)type;

+ (void)clearUserUniqueID;

+ (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(nullable NSString *)registeringUserUniqueID;
+ (BOOL)sendRegisterRequest APPLOG_API_AVALIABLE(5.6.3);

+ (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor;

+ (void)setRequestURLBlock:(nullable BDAutoTrackRequestURLBlock)requestURLBlock;

+ (void)setRequestHostBlock:(nullable BDAutoTrackRequestHostBlock)requestHostBlock;

+ (void)setAppRegion:(nullable NSString *)appRegion;

+ (void)setAppLauguage:(nullable NSString *)appLauguage;

+ (void)setAppTouchPoint:(NSString *)appTouchPoint;

+ (void)setCustomHeaderValue:(nullable id)value forKey:(NSString *)key;

+ (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary;

+ (void)removeCustomHeaderValueForKey:(NSString *)key;

+ (void)setCustomHeaderBlock:(nullable BDAutoTrackCustomHeaderBlock)customHeaderBlock; 

+ (BOOL)eventV3:(NSString *)event params:(nullable NSDictionary *)params;

#pragma mark - ALink
+ (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate;

+ (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL;

#pragma mark - ABTest

+ (nullable id)ABTestConfigValueForKey:(NSString *)key defaultValue:(nullable id)defaultValue;

+ (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue;

+ (void)setExternalABVersion:(nullable NSString *)versions;

+ (nullable NSString *)abVids;

+ (nullable NSString *)allAbVids;

+ (nullable NSDictionary *)allABTestConfigs;

+ (nullable NSDictionary *)allABTestConfigs2;

+ (nullable NSString *)abVidsSync;

+ (nullable NSString *)allAbVidsSync;

+ (nullable NSDictionary *)allABTestConfigsSync;

+ (void)pullABTestConfigs;

#pragma mark - main app only

+ (void)flush;

@end

NS_ASSUME_NONNULL_END
