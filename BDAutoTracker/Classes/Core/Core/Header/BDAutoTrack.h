//
//  BDTracker.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"
#import "BDAutoTrackConfig+AppLog.h"
#import "BDAutoTrackAlinkRouting.h"


@class BDAutoTrackConfig;

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrack : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *rangersDeviceID;

@property (nonatomic, copy, readonly, nullable) NSString *installID;

@property (nonatomic, copy, readonly, nullable) NSString *ssID;

@property (nonatomic, copy, readonly, nullable) NSString *userUniqueID;

@property (nonatomic, readonly, assign) BOOL started;

@property (nonatomic, copy, readonly) NSString *appID;


+ (NSString *)SDKVersion;

@property (nonatomic, readonly, assign) BOOL enableDeferredALink;

+ (instancetype)new __attribute__((unavailable()));
- (instancetype)init __attribute__((unavailable()));

+ (nullable instancetype)trackWithConfig:(BDAutoTrackConfig *)config;

+ (nullable instancetype)trackWithAppID:(NSString *)appID;

- (void)startTrack;

- (void)setUserAgent:(nullable NSString *)userAgent;

- (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID;

- (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID withType:(nullable NSString *)type;

- (void)clearUserUniqueID;

- (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(nullable NSString *)registeringUserUniqueID APPLOG_API_AVALIABLE(6.2.3);

- (BOOL)sendRegisterRequest APPLOG_API_AVALIABLE(5.6.3);

- (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor;

- (void)setRequestURLBlock:(nullable BDAutoTrackRequestURLBlock)requestURLBlock;

- (void)setRequestHostBlock:(nullable BDAutoTrackRequestHostBlock)requestHostBlock;

- (void)setCommonParamtersBlock:(nullable BDAutoTrackCommonParamtersBlock)commonParamtersBlock;

- (void)setAppRegion:(nullable NSString *)appRegion;

- (void)setAppLauguage:(nullable NSString *)appLauguage;

- (void)setCustomHeaderValue:(nullable id)value forKey:(NSString *)key;

- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary;

- (void)removeCustomHeaderValueForKey:(NSString *)key;

- (void)setCustomHeaderBlock:(nullable BDAutoTrackCustomHeaderBlock)customHeaderBlock;

- (void)setActiveCustomParamsBlock:(NSDictionary<NSString *,id> * (^)(void))customParamsBlock;

- (BOOL)eventV3:(NSString *)event params:(nullable NSDictionary *)params;

- (BOOL)eventV3:(NSString *)event;

- (void)setEventHandler:(BDAutoTrackEventHandler)handler
               forTypes:(BDAutoTrackDataType)types;

- (NSString *)currentSessionID;

- (nullable id)ABTestConfigValueForKey:(NSString *)key defaultValue:(nullable id)defaultValue;

- (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue;

- (void)setExternalABVersion:(nullable NSString *)versions;

- (nullable NSString *)abVids;

- (nullable NSString *)allAbVids;

- (nullable NSString *)abExposedVids;

- (nullable NSDictionary *)allABTestConfigs;

- (nullable NSDictionary *)allABTestConfigs2;

- (void)pullABTestConfigs APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use pullABTestConfigs:completion: Instead");

- (void)pullABTestConfigs:(NSTimeInterval)timeout
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate;

- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL;

+ (void)setGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude;


#pragma mark - DurationEvent
- (void)startDurationEvent:(NSString *)eventName;

- (void)pauseDurationEvent:(NSString *)eventName;

- (void)resumeDurationEvent:(NSString *)eventName;

- (void)stopDurationEvent:(NSString *)eventName properties:(NSDictionary *)properties;

- (void)stopDurationEvent:(NSString *)eventName properties:(NSDictionary *)properties customName:(NSString *)customName;

- (void)flush;

- (void)clearAllEvent;

@end

#pragma mark - Special

@interface BDAutoTrack (SharedSpecial)

+ (BOOL)eventV3:(NSString *)event params:(nullable NSDictionary *)params specialParams:(NSDictionary *)specialParams;

+ (BOOL)customEvent:(NSString *)category params:(NSDictionary *)params;

@end

@interface BDAutoTrack (API_DEPRECATED)

- (nullable NSString *)abVidsSync APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use -abVids instead");

- (nullable NSString *)allAbVidsSync APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use -allAbVids instead");

- (nullable NSDictionary *)allABTestConfigsSync  APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use -allABTestConfigs instead");

@end



NS_ASSUME_NONNULL_END

#import "BDAutoTrack+SharedInstance.h"
#import "BDAutoTrack+Profile.h"
