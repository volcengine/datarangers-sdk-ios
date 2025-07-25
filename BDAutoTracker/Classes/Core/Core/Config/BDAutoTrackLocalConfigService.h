//
//  BDAutoTrackLocalConfigService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"
#import "BDAutoTrack.h"
#import "BDCommonEnumDefine.h"

@class BDAutoTrackConfig;

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackLocalConfigService : BDAutoTrackService

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, assign) BOOL logNeedEncrypt;
@property (nonatomic, assign) BOOL autoFetchSettings;
@property (nonatomic, assign) BOOL abTestEnabled;
@property (nonatomic, assign) BOOL showDebugLog;

@property (nonatomic, assign) BOOL enableH5Bridge;
@property (nonatomic, copy) NSArray<NSString *> *H5BridgeAllowedDomainPatterns;
@property (nonatomic, assign) BOOL H5BridgeDomainAllowAll;

@property (nonatomic, assign) BOOL trackEventEnabled;
@property (nonatomic, assign) BOOL autoTrackEnabled;

@property (nonatomic, assign) BOOL trackPageEnabled;
@property (nonatomic, assign) BOOL trackPageClickEnabled;
@property (nonatomic, assign) BOOL trackPageLeaveEnabled;

@property (nonatomic, assign) BOOL screenOrientationEnabled;

@property (nonatomic, assign) BOOL trackGPSLocationEnabled;

@property (atomic, copy) BDAutoTrackServiceVendor serviceVendor;
@property (atomic, copy, nullable) NSDictionary<NSString *,id> *(^activeCustomParamsBlock)(void);
@property (atomic, strong, nullable) BDAutoTrackCustomHeaderBlock customHeaderBlock;
@property (atomic, strong, nullable) BDAutoTrackRequestURLBlock requestURLBlock;
@property (atomic, strong, nullable) BDAutoTrackRequestHostBlock requestHostBlock;
@property (atomic, strong, nullable) BDAutoTrackCommonParamtersBlock commonParamtersBlock;
@property (nonatomic, copy, nullable) NSString *pickerHost;

@property (atomic, strong, nullable) BDAutoTrackRequestURLBlock requestAdvertisingURLBlock;
@property (atomic, strong, nullable) BDAutoTrackRequestHostBlock requestAdvertisingHostBlock;

@property (readonly, nullable) NSString *syncUserUniqueID;
@property (readonly, nullable) NSString *syncUserUniqueIDType;
@property (readonly, nullable) NSString *ssID;

@property (atomic, copy, nullable) NSString *userAgent;
@property (atomic, copy, nullable) NSString *appLauguage;
@property (atomic, copy, nullable) NSString *appRegion;
@property (atomic, copy, nullable) NSString *appTouchPoint;
@property (nonatomic, assign) BOOL eventFilterEnabled;

@property (nonatomic, strong) NSMutableSet<NSString *> *externalVids;

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config;

- (void)saveEventFilterEnabled:(BOOL)enabled;
- (void)saveAppTouchPoint:(nullable NSString *)appTouchPoint;
- (void)saveAppRegion:(nullable NSString *)appRegion;
- (void)saveAppLauguage:(nullable NSString *)appLauguage;
- (void)saveUserAgent:(nullable NSString *)userAgent;

- (void)addSettingParameters:(NSMutableDictionary *)result;

- (void)setCustomHeaderValue:(id)value forKey:(NSString *)key;
- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary;
- (void)removeCustomHeaderValueForKey:(NSString *)key;
- (void)clearCustomHeader;

- (NSMutableDictionary *)currentCustomData;

- (void)updateUser:(nullable NSString *)uuid
              type:(nullable NSString *)userId
              ssid:(nullable NSString *)ssid;

- (void)updateServerTime:(NSDictionary *)responseDict;
- (NSDictionary *)serverTime;

@end


FOUNDATION_EXTERN void bd_addSettingParameters(NSMutableDictionary *result, NSString *appID);

NS_ASSUME_NONNULL_END
