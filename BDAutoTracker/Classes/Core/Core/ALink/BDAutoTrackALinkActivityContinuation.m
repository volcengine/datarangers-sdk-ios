//
//  BDAutoTrackALinkActivityContinuation.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#if TARGET_OS_IOS

#import "BDAutoTrackALinkActivityContinuation.h"
#import "BDAutoTrackURLHostProvider.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackDefaults.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackDeviceHelper.h"
#import <UIKit/UIPasteboard.h>
#import "NSURL+ral_ALink.h"
#import "BDAutoTrackerALinkPasteBoardParser.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrack+Private.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "RangersLog.h"


typedef NSString * AWakeType NS_TYPED_EXTENSIBLE_ENUM;
static AWakeType const AWakeTypeDirect = @"direct";
static AWakeType const AWakeTypeDeferred = @"deferred";
static NSString * const kDirectALinkCachedToken = @"kDirectALinkCachedToken";
static NSString * const kDirectALinkCachedTime = @"kDirectALinkCachedTime";
static NSString * const kDeferredALinkCachedTime = @"kDeferredALinkCachedTime";

static NSString * const k_is_retargeting = @"is_retargeting";

@interface BDAutoTrackALinkActivityContinuation ()
@property (nonatomic) NSString *appID;
@property (nonatomic) BDAutoTrackDefaults *ALinkDefaults;

@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackALinkActivityContinuation

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        _appID = appID;
        _ALinkDefaults = [[BDAutoTrackDefaults alloc] initWithAppID:appID name:@"tracer_data.plist"];
        [self tryDeleteExpiredCache];
        self.associatedTrack = [BDAutoTrack trackWithAppID:appID];
        RL_INFO(self.associatedTrack,@"ALink",@"ALink Enabled");
    }
    return self;
}

- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    NSString *token = [ALinkURL ral_alink_token];
    NSArray <NSURLQueryItem *> *customParams = [ALinkURL ral_alink_custom_params];
    
    if (token) {
        _ALinkURLString = ALinkURL.absoluteString;
        dispatch_async(self.associatedTrack.serialQueue, ^{
            [self handleDeepLinkWithToken:token customParams:(NSArray <NSURLQueryItem *> *)customParams];
        });
        return YES;
    }
    RL_ERROR(self.appID, @"[ALink] ALink failue due to INVALID TOKEN. (%@)", ALinkURL.absoluteString);
    return NO;
}

- (void)continueDeferredALinkActivityWithRegisterUserInfo:(NSDictionary *)userInfo {
    [self handleDeferredDeepLinkWithRegisterUserInfo:userInfo requestUrlString:[[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLALinkAttributionData appID:self.appID] fromDoubleSend:NO];
}

#pragma mark - persistancy
- (NSDictionary *)tracerData {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    NSDictionary *cachedALinkData = [self.ALinkDefaults dictionaryValueForKey:AWakeTypeDirect];
    for (NSString *key in cachedALinkData) {
        NSObject *value = cachedALinkData[key];
        if (![key hasPrefix:@"utm_"]) {
            if ([key isEqualToString:k_is_retargeting] && [value isKindOfClass:[NSNumber class]]) {
                NSNumber *v_is_retargeting = (NSNumber *)value;
                if ([v_is_retargeting boolValue]) {
                    [result setValue:@(1) forKey:k_is_retargeting];
                } else {
                    [result setValue:@(0) forKey:k_is_retargeting];
                }
            } else {
                [result setValue:value forKey:key];
            }
        }
    }
    
    return result.count > 0 ? [result copy] : nil;
}

- (NSDictionary *)alink_utm_data {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSDictionary *cachedALinkData = [self.ALinkDefaults dictionaryValueForKey:AWakeTypeDirect];
    for (NSString *key in cachedALinkData) {
        NSObject *value = cachedALinkData[key];
        if ([key hasPrefix:@"utm_"]) {
            [result setValue:value forKey:key];
        }
    }
    return result.count > 0 ? [result copy] : nil;
}

#pragma mark - private
- (void)handleDeepLinkWithToken:(NSString *)token customParams:(NSArray <NSURLQueryItem *> *)customParams {
    if (self.routingDelegate == nil) {
        RL_WARN(self.associatedTrack,@"ALink",@"DeepLink terminate due to NULL ROUTING DELEGATE.");
        return;
    }
    RL_INFO(self.associatedTrack,@"ALink",@"DeepLink handle start...");

    __block NSString *urlString = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLALinkLinkData appID:self.appID];
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    [parameters setValue:token forKey:@"token"];
    [parameters setValue:self.appID forKey:kBDAutoTrackAPPID];
    [parameters setValue:[self.associatedTrack ssID] forKey:kBDAutoTrackSSID];
    [parameters setValue:[self.associatedTrack userUniqueID] forKey:kBDAutoTrackEventUserID];
    [parameters setValue:[self.associatedTrack rangersDeviceID] forKey:kBDAutoTrackBDDid];
    [parameters setValue:kBDAutoTrackOS forKey:BDAutoTrackOSName];
    [parameters setValue:bd_device_systemVersion() forKey:kBDAutoTrackOSVersion];
    [parameters setValue:bd_device_decivceModel() forKey:kBDAutoTrackDecivceModel];
    
    NSMutableCharacterSet *lastSet = [[NSMutableCharacterSet alloc] init];
    [lastSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"-_.!~*'()"]];
    [lastSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    for (NSURLQueryItem *qItem in customParams) {
        [parameters setValue:[qItem.value stringByAddingPercentEncodingWithAllowedCharacters:lastSet] forKey:qItem.name];
    }
    
    NSArray *filterFieldKeys =  bd_remoteSettingsForAppID(self.appID).sensitiveFields;
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([filterFieldKeys containsObject:key]) {
            
        } else {
            urlString = bd_appendQueryToURL(urlString, key, obj);
        }
    }];
    
    BDAutoTrackNetworkEncryptor *encryptor = self.associatedTrack.networkManager.encryptor;
    urlString = [encryptor encryptUrl:urlString allowedKeys:@[kBDAutoTrackAPPID]];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:1];
    [URLRequest setHTTPMethod:@"GET"];
    [URLRequest setAllHTTPHeaderFields: bd_headerField(self.appID)];
    
    RL_DEBUG(self.appID, @"[ALink] DeepLink request ... (%@)", URLRequest.URL.absoluteString);
    [[NSURLSession.sharedSession dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            RL_ERROR(self.appID, @"[ALink] DeepLink failure due to request failure. (%@)", error.localizedDescription);
            return;
        }
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSMutableDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *responseDicData = responseDic[@"data"];
            if ([responseDic isKindOfClass:NSDictionary.class] &&
                [responseDic[kBDAutoTrackMessage] isEqualToString:BDAutoTrackMessageSuccess] &&
                [responseDicData isKindOfClass:[NSDictionary class]] &&
                responseDicData.count > 0) {
                if ([self.routingDelegate respondsToSelector:@selector(onALinkData:error:)]) {
                    RL_DEBUG(self.associatedTrack,@"ALink",@"DeepLink successful. (%@)", responseDicData);
                    [self.routingDelegate onALinkData:[[NSDictionary alloc] initWithDictionary:responseDicData copyItems:YES] error:nil];
                }
                [self.ALinkDefaults setValue:token forKey:kDirectALinkCachedToken];
                [self.ALinkDefaults setValue:responseDicData forKey:AWakeTypeDirect];
                [self.ALinkDefaults setValue:@([[NSDate date] timeIntervalSince1970]) forKey:kDirectALinkCachedTime];
                [self.ALinkDefaults saveDataToFile];
                
                [self sendAwakeEvent:AWakeTypeDirect];
            } else {
                RL_ERROR(self.associatedTrack,@"ALink",@"DeepLink failure due to INVALID RESPONSE. (%@)", responseDic);
            }
        } else {
            RL_ERROR(self.associatedTrack,@"ALink",@"DeepLink failure due to request failure. (statusCode:%d)", ((NSHTTPURLResponse *)response).statusCode);
        }
    }] resume];
}

- (nullable BDAutoTrackerALinkPasteBoardParser *)ddl_preparePasteBoardContentParser {
    BDAutoTrackerALinkPasteBoardParser *parser;
    
    if ([self.routingDelegate respondsToSelector:@selector(shouldALinkSDKAccessPasteBoard)] &&
        [self. routingDelegate shouldALinkSDKAccessPasteBoard]) {
        if (@available(iOS 10.0, *)) {
            if ([[UIPasteboard generalPasteboard] hasStrings] == NO) {
                return nil;
            }
        }
        
        NSString *pb_stringItem = [[UIPasteboard generalPasteboard] string];
        if ([pb_stringItem hasPrefix:s_pb_DemandPrefix]) {
            parser = [[BDAutoTrackerALinkPasteBoardParser alloc] initWithPasteBoardItem:pb_stringItem];
            
            [[UIPasteboard generalPasteboard] setString:@""];
        }
    }
    
    return parser;
}

- (void)handleDeferredDeepLinkWithRegisterUserInfo:(NSDictionary *)userInfo requestUrlString:(NSString *)urlString fromDoubleSend:(BOOL)doubleSend {
    RL_INFO(self.associatedTrack,@"ALink",@"DeferredDeepLink handle start ...");
    if (self.routingDelegate == nil) {
        RL_WARN(self.associatedTrack,@"ALink",@"DeferredDeepLink terminate deferred link duo to Delegate is NULL");
        return;
    }
    if (!urlString) {
        RL_WARN(self.associatedTrack,@"ALink",@"DeferredDeepLink terminate deferred link duo to request urlString is NULL");
        return;
    }
    
    urlString = bd_appendQueryToURL(urlString, @"aid", self.appID);
    
    NSString *userUniqueID = userInfo[kBDAutoTrackNotificationUserUniqueID];
    NSString *SSID = userInfo[kBDAutoTrackNotificationSSID];
    NSString *bd_did = userInfo[kBDAutoTrackNotificationRangersDeviceID];

    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackEventUserID, userUniqueID);
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackSSID, SSID);
    urlString = bd_appendQueryToURL(urlString, @"bd_did", bd_did);
    
    BDAutoTrackerALinkPasteBoardParser *parser = [self ddl_preparePasteBoardContentParser];
    NSString *pb_attrQueries = [parser allQueryString];
    NSString *pb_abVersion = [parser ab_version];
    NSString *pb_tr_web_ssid = [parser tr_web_ssid];
    
    BDAutoTrackABConfig *ABService = self.associatedTrack.abTester;
    ABService.alinkABVersions = pb_abVersion;
    
    BDAutoTrackLocalConfigService *localConfigService =  self.associatedTrack.localConfig;
    [localConfigService setCustomHeaderValue:pb_tr_web_ssid forKey:kBDAutoTrack__tr_web_ssid];
    
    urlString = bd_appendQueryStringToURL(urlString, pb_attrQueries);
    
    if (doubleSend) {
    } else {
        BDAutoTrackNetworkEncryptor *encryptor = self.associatedTrack.networkManager.encryptor;
        urlString = [encryptor encryptUrl:urlString allowedKeys:@[kBDAutoTrackAPPID]];
    }
    
    BDAutoTrackLocalConfigService *localConfig = self.associatedTrack.localConfig;
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
    [URLRequest setHTTPMethod:@"POST"];
    [URLRequest setAllHTTPHeaderFields: bd_headerField(self.appID)];

    BDAutoTrackRegisterService *registerService = bd_registerServiceForAppID(self.appID);
    
    NSMutableDictionary *HTTPBodyDic = [[NSMutableDictionary alloc] init];
    bd_addBodyNetworkParams(HTTPBodyDic, self.appID);
    [HTTPBodyDic setValue:self.appID forKey:kBDAutoTrackAPPID];
    [HTTPBodyDic setValue:[self.associatedTrack rangersDeviceID] forKey:kBDAutoTrackBDDid];
    [HTTPBodyDic setValue:[self.associatedTrack installID] forKey:kBDAutoTrackInstallID];

    [HTTPBodyDic setValue:localConfig.userAgent forKey:@"ua"];
    [HTTPBodyDic setValue:@(registerService.isNewUser) forKey:@"is_new_user"];
    BOOL exist_app_cahce = ![[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch];
    [HTTPBodyDic setValue:@(exist_app_cahce) forKey:@"exist_app_cache"];
    [HTTPBodyDic setValue:bd_sandbox_bundleIdentifier() forKey:kBDAutoTrackPackage];

    if (doubleSend) {
        bd_buildBodyData_without_encryptor(URLRequest, HTTPBodyDic, self.associatedTrack.networkManager);
    } else {
        bd_buildBodyData(URLRequest, HTTPBodyDic, self.associatedTrack.networkManager);
    }

    
    RL_DEBUG(self.associatedTrack,@"ALink",@"DeferredDeepLink request ... (%@)",URLRequest.URL.absoluteString);
    
    [[NSURLSession.sharedSession dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (doubleSend) {
            return;
        }
        if (error){
            RL_ERROR(self.associatedTrack,@"ALink",@"DeferredDeepLink failure due to request fail (%@)", error.localizedDescription);
            return;
        }
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            NSMutableDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSString *responseDicMsg = responseDic[kBDAutoTrackMessage];
            NSMutableDictionary *responseDicData = responseDic[@"data"];
            
            if ([responseDic isKindOfClass:[NSMutableDictionary class]] &&
                [responseDicMsg isEqualToString:BDAutoTrackMessageSuccess] &&
                [responseDicData isKindOfClass:[NSMutableDictionary class]] &&
                responseDicData.count > 0) {
                
                if ([responseDicData[@"is_first_launch"] isKindOfClass:[NSNumber class]] &&
                    [responseDicData[@"is_first_launch"] boolValue]) {
                    if ([self.routingDelegate respondsToSelector:@selector(onAttributionData:error:)]) {
                        RL_DEBUG(self.associatedTrack,@"ALink",@"DeferredDeepLink successful. (%@)", responseDicData);
                        [self.routingDelegate onAttributionData:[[NSDictionary alloc] initWithDictionary:responseDicData copyItems:YES] error:nil];
                    }
                    
                } else {
                    RL_DEBUG(self.associatedTrack,@"ALink",@"DeferredDeepLink IS NOT FIRST LAUNCH");
                }
                
                if (responseDicData[@"is_first_launch"] != nil) {
                    responseDicData[@"is_first_launch"] = @(NO);
                }
                [self.ALinkDefaults setValue:responseDicData forKey:AWakeTypeDeferred];
                [self.ALinkDefaults setValue:@([[NSDate date] timeIntervalSince1970]) forKey:kDeferredALinkCachedTime];
                [self.ALinkDefaults saveDataToFile];
                
                [self sendAwakeEvent:AWakeTypeDeferred];
            } else {
                RL_ERROR(self.associatedTrack,@"ALink",@"DeferredDeepLink failure due to INVALID RESPONSE (%@)", responseDic);
            }
        } else {
            RL_ERROR(self.associatedTrack,@"ALink",@"DeferredDeepLink failure due to request fail (statusCode:%d)", ((NSHTTPURLResponse *)response).statusCode);
        }
    }] resume];
}

- (void)sendAwakeEvent:(AWakeType)awakeType {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:awakeType forKey:kBDAutoTrackLinkType];
    [params setValue:self.ALinkURLString forKey:kBDAutoTrackDeepLinkUrl];
    [self.associatedTrack eventV3:@"$invoke" params:params];
}

- (void)tryDeleteExpiredCache {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval directALinkCachedTime = [_ALinkDefaults doubleValueForKey:kDirectALinkCachedTime],
                   deferredALinkCachedTime = [_ALinkDefaults doubleValueForKey:kDeferredALinkCachedTime];
    __unused NSString *directALinkCachedToken = [_ALinkDefaults stringValueForKey:kDirectALinkCachedToken];  // wake data
    
    NSTimeInterval aMonth = 30 * 24 * 60 * 60;
    BOOL isDirectCacheExpired   = directALinkCachedTime  > 1  && currentTime - directALinkCachedTime   > aMonth;
    BOOL isDeferredCacheExpired = deferredALinkCachedTime > 1 && currentTime - deferredALinkCachedTime > aMonth;
    if (isDirectCacheExpired) {
        RL_DEBUG(self.associatedTrack,@"ALink",@"direct cache expired");
        [_ALinkDefaults setValue:nil forKey:kDirectALinkCachedTime];
        [_ALinkDefaults setValue:nil forKey:kDirectALinkCachedToken];
        [_ALinkDefaults setValue:nil forKey:AWakeTypeDirect];
    }
    if (isDeferredCacheExpired) {
        RL_DEBUG(self.associatedTrack,@"ALink",@"deferred cache expired");
        [_ALinkDefaults setValue:nil forKey:kDeferredALinkCachedTime];
        [_ALinkDefaults setValue:nil forKey:AWakeTypeDeferred];
    }
    if (isDirectCacheExpired || isDeferredCacheExpired) {
        [_ALinkDefaults saveDataToFile];
    }
}

@end

#endif
