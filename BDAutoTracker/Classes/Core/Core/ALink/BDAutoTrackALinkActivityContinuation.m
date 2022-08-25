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
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackDeviceHelper.h"
#import <UIKit/UIPasteboard.h>
#import "NSURL+ral_ALink.h"
#import "BDAutoTrackerALinkPasteBoardParser.h"
#import "BDAutoTrackABTest.h"
#import "BDAutoTrack+Private.h"
#import "RangersAppLogConfig.h"
#import "BDTrackerCoreConstants.h"

#if __has_include("RALInstallExtraParams.h")
#import "RALInstallExtraParams.h"
#endif
#import "RangersLog.h"


typedef NSString * AWakeType NS_TYPED_EXTENSIBLE_ENUM;  // ALink唤醒类型
static AWakeType const AWakeTypeDirect = @"direct";     // 既是ALink数据缓存的Key，也是唤醒事件的属性常量。不要更改。
static AWakeType const AWakeTypeDeferred = @"deferred";
static NSString * const kDirectALinkCachedToken = @"kDirectALinkCachedToken";   // 直接ALink数据对应的Token
static NSString * const kDirectALinkCachedTime = @"kDirectALinkCachedTime";     // 直接ALink数据的缓存时间
static NSString * const kDeferredALinkCachedTime = @"kDeferredALinkCachedTime"; // 延迟ALink数据的缓存时间

static NSString * const k_is_retargeting = @"is_retargeting";

@interface BDAutoTrackALinkActivityContinuation ()
@property (nonatomic) NSString *appID;
@property (nonatomic) BDAutoTrackDefaults *ALinkDefaults;

/// appID关联的track实例
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
        RL_DEBUG(appID, @"[ALink] ALink Enabled");
    }
    return self;
}

/// 处理Universal Link形式或Custom URL Scheme形式的ALink
/// @param ALinkURL 深度链接URL。可以是Universal Link 或 Custom URL Scheme
/// @return 是否为有效的ALink
- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    NSString *token = [ALinkURL ral_alink_token];
    NSArray <NSURLQueryItem *> *customParams = [ALinkURL ral_alink_custom_params];
    
    if (token) {
        _ALinkURLString = ALinkURL.absoluteString;
        /// [BDAutoTrack setRequestHostBlock:block] 设置私有化域名是异步操作，放到serialQueue中去设置
        /// 这会导致deeplink冷启动走到这里的时候私有化域名还没有设置成功，导致alink_data请求发到默认的saas地址了
        /// 这里修复方案是要放到serialQueue中去执行alink_data请求
        dispatch_async(self.associatedTrack.serialQueue, ^{
            [self handleDeepLinkWithToken:token customParams:(NSArray <NSURLQueryItem *> *)customParams];
        });
        return YES;
    }
    RL_ERROR(self.appID, @"[ALink] ALink failue due to INVALID TOKEN. (%@)", ALinkURL.absoluteString);
    return NO;
}

/// Continue defferred alink activity. Depends on register IDs.
/// Called at App first startup
/// @param userInfo register success notification user info
- (void)continueDeferredALinkActivityWithRegisterUserInfo:(NSDictionary *)userInfo {
    [self handleDeferredDeepLinkWithRegisterUserInfo:userInfo];
}

#pragma mark - persistancy
/// HTTPBody 中的 tracer_data
- (NSDictionary *)tracerData {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    /* 1. 添加ALink Data */
    NSDictionary *cachedALinkData = [self.ALinkDefaults dictionaryValueForKey:AWakeTypeDirect];
    for (NSString *key in cachedALinkData) {
        NSObject *value = cachedALinkData[key];
        if (![key hasPrefix:@"utm_"]) {
            if ([key isEqualToString:k_is_retargeting] && [value isKindOfClass:[NSNumber class]]) {
                // 单独处理 is_retargeting。因为数据流不处理bool，所以要以整型上报。
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

/// Handle deeplink ALink
/// @param token ALink token
/// @param customParams ALink user-defined custom query params
- (void)handleDeepLinkWithToken:(NSString *)token customParams:(NSArray <NSURLQueryItem *> *)customParams {
    if (self.routingDelegate == nil) {
        RL_WARN(self.appID, @"[ALink] DeepLink terminate due to NULL ROUTING DELEGATE.");
        return;
    }
    RL_DEBUG(self.appID, @"[ALink] DeepLink start...");
    
    /* 若有缓存，则返回缓存中数据。不发起请求。 */
//    NSString *cachedToken = [self.ALinkDefaults stringValueForKey:kDirectALinkCachedToken];
//    NSDictionary *cachedALinkData = [self.ALinkDefaults dictionaryValueForKey:AWakeTypeDirect];
//    if ([token isEqualToString:cachedToken] && [cachedALinkData isKindOfClass:NSDictionary.class]) {
//        if ([self.routingDelegate respondsToSelector:@selector(onALinkData:error:)]) {
//            [self.routingDelegate onALinkData:cachedALinkData error:nil];
//        }
//        // 发送$invoke事件
//        [self sendAwakeEvent:AWakeTypeDirect];
//        return;
//    }
    
    /* 发起请求 */
    __block NSString *urlString = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLALinkLinkData appID:self.appID];
    urlString = bd_appendQueryToURL(urlString, @"token", token);
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackAPPID, self.appID);                                  //aid
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackSSID, [self.associatedTrack ssID]);                  //ssid
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackEventUserID, [self.associatedTrack userUniqueID]);   //user_unique_id
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackBDDeviceID, [self.associatedTrack rangersDeviceID]);      //bdid
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackOS, BDAutoTrackOSName);                              //os
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackOSVersion, bd_device_systemVersion());               //os_version
    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackDecivceModel, bd_device_decivceModel());             //device_model
    
    NSString *unique = self.associatedTrack.identifier.identifierForTracking;
    if (unique.length > 0) {
        urlString = bd_appendQueryToURL(urlString, kBDAutoTrackIdentifierForTracking, unique);
    }

    NSMutableCharacterSet *lastSet = [[NSMutableCharacterSet alloc] init];
    [lastSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"-_.!~*'()"]];
    [lastSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];

    for (NSURLQueryItem *qItem in customParams) {
        urlString = bd_appendQueryToURL(urlString, qItem.name,  [qItem.value stringByAddingPercentEncodingWithAllowedCharacters:lastSet]);
    }
    
    // tt_info 加密
    if (bd_settingsServiceForAppID(self.appID).logNeedEncrypt) {
        urlString = bd_getCompressedDecoratedBase64URLStringWithAllowedKeys(urlString, @[kBDAutoTrackAPPID], self.encryptionDelegate ?: BDAutoTrack.bdEncryptor);
    }
    
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:1];
    [URLRequest setHTTPMethod:@"GET"];
    [URLRequest setAllHTTPHeaderFields: bd_headerField(YES, self.appID)];
    
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
                    // 回调用户路由代码
                    RL_DEBUG(self.appID, @"[ALink] DeepLink successful. (%@)", responseDicData);
                    [self.routingDelegate onALinkData:[[NSDictionary alloc] initWithDictionary:responseDicData copyItems:YES] error:nil];
                }
                [self.ALinkDefaults setValue:token forKey:kDirectALinkCachedToken];
                [self.ALinkDefaults setValue:responseDicData forKey:AWakeTypeDirect];
                [self.ALinkDefaults setValue:@([[NSDate date] timeIntervalSince1970]) forKey:kDirectALinkCachedTime];
                [self.ALinkDefaults saveDataToFile];
                
                // 发送$invoke事件
                [self sendAwakeEvent:AWakeTypeDirect];
            } else {
                RL_ERROR(self.appID, @"[ALink] DeepLink failure due to INVALID RESPONSE. (%@)", responseDic);
            }
        } else {
            RL_ERROR(self.appID, @"[ALink] DeepLink failure due to request failure. (statusCode:%d)", ((NSHTTPURLResponse *)response).statusCode);
        }
    }] resume];
}

- (nullable BDAutoTrackerALinkPasteBoardParser *)ddl_preparePasteBoardContentParser {
    // In iOS 14+, we can check the pattern of a paste board item without notifying the users.
    // But currently the item is not in the way that we can do check. (Could be a URL format)
    BDAutoTrackerALinkPasteBoardParser *parser;
    
    if ([self.routingDelegate respondsToSelector:@selector(shouldALinkSDKAccessPasteBoard)] &&
        [self. routingDelegate shouldALinkSDKAccessPasteBoard]) {
        if (@available(iOS 10.0, *)) {
            if ([[UIPasteboard generalPasteboard] hasStrings] == NO) {
                return nil;
            }
        }
        
        // get the first string in pasteboard 
        NSString *pb_stringItem = [[UIPasteboard generalPasteboard] string];
        if ([pb_stringItem hasPrefix:s_pb_DemandPrefix]) {
            parser = [[BDAutoTrackerALinkPasteBoardParser alloc] initWithPasteBoardItem:pb_stringItem];
            
            // remove the first pasteboard item
            [[UIPasteboard generalPasteboard] setString:@""];
        }
    }
    
    return parser;
}

/// 处理Deferred Deep Link场景。发生于应用首启时（包括卸载重装）。
/// @discussion 需要归因。请求归因接口。
/// @param userInfo Register success notification userinfo
- (void)handleDeferredDeepLinkWithRegisterUserInfo:(NSDictionary *)userInfo {
    if (self.routingDelegate == nil) {
        RL_WARN(self.appID,@"[ALink] DeferredDeepLink terminate deferred link duo to Delegate is NULL");
        return;
    }
    RL_DEBUG(self.appID,@"[ALink] DeferredDeepLink start ...");
    NSString *urlString = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLALinkAttributionData appID:self.appID];
    urlString = bd_appendQueryToURL(urlString, @"aid", self.appID);
    

//    NSString *userUniqueID = userInfo[kBDAutoTrackNotificationUserUniqueID];
//    NSString *SSID = userInfo[kBDAutoTrackNotificationSSID];
//    NSString *bd_did = userInfo[kBDAutoTrackNotificationRangersDeviceID];
//    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackEventUserID, userUniqueID);
//    urlString = bd_appendQueryToURL(urlString, kBDAutoTrackSSID, SSID);
//    urlString = bd_appendQueryToURL(urlString, @"bd_did", bd_did);
    
    BDAutoTrackerALinkPasteBoardParser *parser = [self ddl_preparePasteBoardContentParser];
    NSString *pb_attrQueries = [parser allQueryString];
    NSString *pb_abVersion = [parser ab_version];
    NSString *pb_tr_web_ssid = [parser tr_web_ssid];
    
    /* expose ABVersion */
    [[BDAutoTrack trackWithAppID:self.appID].abtestManager setALinkABVersions:pb_abVersion];

    /* store $tr_web_ssid to custom */
    BDAutoTrackLocalConfigService *localConfigService = bd_settingsServiceForAppID(self.appID);
    [localConfigService setCustomHeaderValue:pb_tr_web_ssid forKey:kBDAutoTrack__tr_web_ssid];
    
    urlString = bd_appendQueryStringToURL(urlString, pb_attrQueries);
    
    // tt_info 加密
    if (bd_settingsServiceForAppID(self.appID).logNeedEncrypt) {
        urlString = bd_getCompressedDecoratedBase64URLStringWithAllowedKeys(urlString, @[kBDAutoTrackAPPID], self.encryptionDelegate ?: BDAutoTrack.bdEncryptor);
    }
    
    NSURL *URL = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
    [URLRequest setHTTPMethod:@"POST"];
    [URLRequest setAllHTTPHeaderFields: bd_headerField(YES, self.appID)];

    /* build HTTP body */
    BDAutoTrackLocalConfigService *localConfig = bd_settingsServiceForAppID(self.appID);
    NSMutableDictionary *HTTPBodyDic = [[NSMutableDictionary alloc] init];
    bd_addBodyNetworkParams(HTTPBodyDic, self.appID);
    [HTTPBodyDic setValue:self.appID forKey:kBDAutoTrackAPPID];
    [HTTPBodyDic setValue:[self.associatedTrack rangersDeviceID] forKey:kBDAutoTrackBDDeviceID];
    [HTTPBodyDic setValue:[self.associatedTrack installID] forKey:kBDAutoTrackInstallID];
    [HTTPBodyDic setValue:localConfig.userAgent forKey:@"ua"];
    [HTTPBodyDic setValue:@(self.associatedTrack.identifier.isNewUser) forKey:@"is_new_user"];
    BOOL exist_app_cahce = ![[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch];
    [HTTPBodyDic setValue:@(exist_app_cahce) forKey:@"exist_app_cache"];
#ifdef DEBUG
    bd_buildBodyData(URLRequest, HTTPBodyDic, localConfig.logNeedEncrypt, YES, [self encryptionDelegate]);
#else
    bd_buildBodyData(URLRequest, HTTPBodyDic, localConfig.logNeedEncrypt, YES, [self encryptionDelegate]);
#endif
    
    RL_DEBUG(self.appID,@"[ALink] DeferredDeepLink request ... (%@)",URLRequest.URL.absoluteString);
    
    [[NSURLSession.sharedSession dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            RL_ERROR(self.appID,@"[ALink] DeferredDeepLink failure due to request fail (%@)", error.localizedDescription);
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
                        RL_DEBUG(self.appID,@"[ALink] DeferredDeepLink successful. (%@)", responseDicData);
                        [self.routingDelegate onAttributionData:[[NSDictionary alloc] initWithDictionary:responseDicData copyItems:YES] error:nil];
                    }
                    
                } else {
                    RL_DEBUG(self.appID,@"[ALink] DeferredDeepLink IS NOT FIRST LAUNCH");
                }
                
                
                // 存储响应内容
                if (responseDicData[@"is_first_launch"] != nil) {
                    responseDicData[@"is_first_launch"] = @(NO);
                }
                [self.ALinkDefaults setValue:responseDicData forKey:AWakeTypeDeferred];
                [self.ALinkDefaults setValue:@([[NSDate date] timeIntervalSince1970]) forKey:kDeferredALinkCachedTime];
                [self.ALinkDefaults saveDataToFile];
                
                // 发送$invoke事件
                [self sendAwakeEvent:AWakeTypeDeferred];
            } else {
                RL_ERROR(self.appID,@"[ALink] DeferredDeepLink failure due to INVALID RESPONSE (%@)", responseDic);
            }
        } else {
            RL_ERROR(self.appID,@"[ALink] DeferredDeepLink failure due to request fail (statusCode:%d)", ((NSHTTPURLResponse *)response).statusCode);
        }
    }] resume];
}

#pragma mark - 唤醒事件
/// 发送唤醒事件
/// @param awakeType 链接类型. 取值为 direct | deferred
- (void)sendAwakeEvent:(AWakeType)awakeType {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:awakeType forKey:kBDAutoTrackLinkType];
    [params setValue:self.ALinkURLString forKey:kBDAutoTrackDeepLinkUrl];
    [self.associatedTrack eventV3:@"$invoke" params:params];
}

/*! 删除过期的缓存 */
- (void)tryDeleteExpiredCache {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval directALinkCachedTime = [_ALinkDefaults doubleValueForKey:kDirectALinkCachedTime],
                   deferredALinkCachedTime = [_ALinkDefaults doubleValueForKey:kDeferredALinkCachedTime];
    __unused NSString *directALinkCachedToken = [_ALinkDefaults stringValueForKey:kDirectALinkCachedToken];  // wake data
    
    NSTimeInterval aMonth = 30 * 24 * 60 * 60;
    BOOL isDirectCacheExpired   = directALinkCachedTime  > 1  && currentTime - directALinkCachedTime   > aMonth;
    BOOL isDeferredCacheExpired = deferredALinkCachedTime > 1 && currentTime - deferredALinkCachedTime > aMonth;
    if (isDirectCacheExpired) {
        RL_DEBUG(self.appID, @"[ALink] direct cache expired");
        [_ALinkDefaults setValue:nil forKey:kDirectALinkCachedTime];
        [_ALinkDefaults setValue:nil forKey:kDirectALinkCachedToken];
        [_ALinkDefaults setValue:nil forKey:AWakeTypeDirect];
    }
    if (isDeferredCacheExpired) {
        RL_DEBUG(self.appID, @"[ALink] deferred cache expired");
        [_ALinkDefaults setValue:nil forKey:kDeferredALinkCachedTime];
        [_ALinkDefaults setValue:nil forKey:AWakeTypeDeferred];
    }
    if (isDirectCacheExpired || isDeferredCacheExpired) {
        [_ALinkDefaults saveDataToFile];
    }
}

#pragma mark computed property
- (id<BDAutoTrackEncryptionDelegate>)encryptionDelegate {
    return self.associatedTrack.encryptionDelegate;
}

@end

#endif
