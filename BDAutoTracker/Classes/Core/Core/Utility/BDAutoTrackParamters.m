//
//  BDAutoTrackParamters.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackParamters.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDAutoTrackUtility.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackABTest.h"
#import "BDAutoTrackApplication.h"

#if DEBUG && __has_include("RALInstallExtraParams.h")
#import "RALInstallExtraParams.h"
#endif

#import "NSDictionary+VETyped.h"
#import "NSData+VEGZip.h"
#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrack+Private.h"

static NSString *const kTimeSyncStorageKey = @"kTimeSyncStorageKey";

BOOL _bd_URLHasQuery(NSString *url) {
    NSURL *urlObj = [NSURL URLWithString:url];
    return [urlObj query] && [urlObj query].length > 0;
}

NSString *bd_appendQueryDictToURL(NSString *url, NSDictionary *queries) {
    if ([queries count] == 0) {
        return [url copy];
    }
    
    NSString *pairs = bd_queryFromDictionary(queries);
    NSString *ans = bd_appendQueryStringToURL(url, pairs);
    return ans;
}

NSString *bd_appendQueryStringToURL(NSString *url, NSString *pairs) {
    if ([pairs length] == 0) {
        return [url copy];
    }
    
    NSString *ans;
    if (_bd_URLHasQuery(url)) {
        ans = [NSString stringWithFormat:@"%@&%@", url, pairs];
    } else if ([url hasSuffix:@"?"]) {
        ans = [NSString stringWithFormat:@"%@%@", url, pairs];
    } else {
        ans = [NSString stringWithFormat:@"%@?%@", url, pairs];
    }
    return ans;
}

NSString *bd_appendQueryToURL(NSString *url, NSString *key, NSString *value) {
    if ([key length] == 0) {
        return [url copy];
    }
    
    NSString *ans;
    NSString *pair = [NSString stringWithFormat:@"%@=%@", key, value ?: @""];
    if(_bd_URLHasQuery(url)) {
        ans = [NSString stringWithFormat:@"%@&%@", url, pair];
    } else if ([url hasSuffix:@"?"]) {
        ans = [NSString stringWithFormat:@"%@%@", url, pair];
    } else {
        ans = [NSString stringWithFormat:@"%@?%@", url, pair];
    }
    return ans;
}

NSMutableDictionary *bd_getCompressedDecoratedBase64QueryDictWithAllowedKeys(NSMutableDictionary *parameters, NSArray *allowedKeys, id<BDAutoTrackEncryptionDelegate> encryptionDelegate) {
    /* `allowedKeys` will show in plain-text keys and be contained in tt_info's value(which is the encoded version of possible multiple keys),
     * but the redundancy it's OK to the server side
     */
    NSMutableDictionary *allowedParameters = [NSMutableDictionary new];
    for (NSString *key in parameters) {
        if([allowedKeys containsObject:key]) {
            [allowedParameters setValue:parameters[key] forKey:key];
        }
    }
    
    NSString *query = bd_queryFromDictionary(parameters);
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    
    /* GZIP */
    NSError *error;
    queryData = [queryData ve_dataByGZipCompressingWithError:&error];
    
    /* 加密 */
    if ([encryptionDelegate respondsToSelector:@selector(encryptData:error:)]) {
        if (!error) {
            queryData = [encryptionDelegate encryptData:queryData error:&error];
        }
    }
    
    /* url-safe base64 */
    NSString *base64QueryStr = [queryData base64EncodedStringWithOptions:0];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    [allowedParameters setValue:base64QueryStr forKey:kBDAutoTrackTTInfo];
    return allowedParameters;
}

NSString *bd_getCompressedDecoratedBase64URLStringWithAllowedKeys(NSString *urlString, NSArray *allowedKeys, id<BDAutoTrackEncryptionDelegate> encryptionDelegate) {
    
    NSURLComponents *urlComp = [NSURLComponents componentsWithString:urlString];
    
    // 获取 url 中的 query 部分加密
//    NSString *query = urlComp.query;
    
    NSString *query = [NSURL URLWithString:urlString].query;
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    
    /* GZIP */
    NSError *error;
    queryData = [queryData ve_dataByGZipCompressingWithError:&error];
    
    /* 加密 */
    if ([encryptionDelegate respondsToSelector:@selector(encryptData:error:)]) {
        if (!error) {
            queryData = [encryptionDelegate encryptData:queryData error:&error];
        }
    }
    
    /* url-safe base64 */
    NSString *base64QueryStr = [queryData base64EncodedStringWithOptions:0];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    
    /* 创建一个新的 URL 包含 tt_info 加密字段和 allowedKeys */
    NSMutableArray<NSURLQueryItem *> *newQueryItems = [NSMutableArray array];
    [newQueryItems addObject:[NSURLQueryItem queryItemWithName:kBDAutoTrackTTInfo value:base64QueryStr]];
    /* `allowedKeys` will show in plain-text keys and be contained in tt_info's value(which is the encoded version of possible multiple keys),
     * but the redundancy it's OK to the server side
     */
    for (NSURLQueryItem *item in urlComp.queryItems) {
        if([allowedKeys containsObject:item.name]) {
            [newQueryItems addObject:item];
        }
    }
    urlComp.queryItems = newQueryItems;
    
    return urlComp.string;
}

#pragma mark Network Parameters
/// 获取 HTTP请求报文的header
/// @param needCompress 是否需要添加gzip
/// @param appID appID
/// @return HTTP请求报文的header
/// @discussion 目前的caller都是传 needCompress = YES
NSMutableDictionary * bd_headerField(BOOL needCompress, NSString *appID) {
    NSMutableDictionary *headerFiled = [NSMutableDictionary new];

    [headerFiled setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerFiled setValue:@"application/json" forKey:@"Accept"];
    [headerFiled setValue:@"keep-alive" forKey:@"Connection"];
    if (needCompress) {
        [headerFiled setValue:@"gzip" forKey:@"Content-Encoding"];
    }
    NSString *aid = [appID mutableCopy];
    [headerFiled setValue:aid forKey:kBDAutoTrackAPPID];

    return headerFiled;
}

static void addSharedNetworkParams(NSMutableDictionary *result, NSString *appID) {
#if TARGET_OS_IOS
    [result setValue:@"ios" forKey:kBDAutoTrackPlatform];
    [result setValue:@"ios" forKey:kBDAutoTrackSDKLib];
#elif TARGET_OS_OSX
    [result setValue:@"macos" forKey:kBDAutoTrackPlatform];
    [result setValue:@"macos" forKey:kBDAutoTrackSDKLib];
#endif
    
    [result setValue:bd_device_platformName() forKey:kBDAutoTrackDecivcePlatform];
    [result setValue:@(BDAutoTrackerSDKVersion) forKey:kBDAutoTrackerSDKVersion];
    [result setValue:BDAutoTrackOSName forKey:kBDAutoTrackOS];
    [result setValue:bd_device_systemVersion() forKey:kBDAutoTrackOSVersion];
    [result setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion];
    [result setValue:bd_device_decivceModel() forKey:kBDAutoTrackDecivceModel];
//    [result setValue:bd_device_platformName() forKey:kBDAutoTrackDecivcePlatform];  introduced between 5.2.0 - 5.3.0. Comment to remove it from header. 
    [result setValue:@(bd_sandbox_isUpgradeUser()) forKey:kBDAutoTrackIsUpgradeUser];
    [result setValue: [BDAutoTrack trackWithAppID:appID].identifier.identifierForTracking forKey:kBDAutoTrackIdentifierForTracking];
}

void bd_addQueryNetworkParams(NSMutableDictionary *result, NSString *appID) {
    addSharedNetworkParams(result, appID);
#if TARGET_OS_IOS
    
    [result setValue:[[BDAutoTrack trackWithAppID:appID].identifier identifierForVendor] forKey:@"idfv"];
#endif
    [result setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackerVersionCode];
}

void bd_addBodyNetworkParams(NSMutableDictionary *result, NSString *appID) {
/* shared params */
    addSharedNetworkParams(result, appID);
    
/* carrier related params */
#if TARGET_OS_IOS
    NSDictionary *carrierJSON = [BDAutoTrackEnviroment sharedEnviroment].carrier;
    NSString *carrierMCC = [carrierJSON objectForKey:@"mobileCountryCode"];
    NSString *carrierMNC = [carrierJSON objectForKey:@"mobileNetworkCode"];
    if(!carrierMCC) carrierMCC = @"";
    if(!carrierMNC) carrierMNC = @"";
    [result setValue:[NSString stringWithFormat:@"%@%@",carrierMCC,carrierMNC] forKey:kBDAutoTrackMCCMNC];
    
    NSString *carrierName = [carrierJSON objectForKey:@"carrierName"];
    if(!carrierName) carrierName = @"";
    [result setValue:carrierName forKey:kBDAutoTrackCarrier];
#endif
    
    [result setValue:[BDAutoTrackEnviroment sharedEnviroment].connectionTypeName forKey:kBDAutoTrackAccess];
    
/* device releated params */
    NSInteger timeZoneOffset = bd_device_timeZoneOffset();
    [result setValue:@(timeZoneOffset) forKey:kBDAutoTrackTimeZoneOffSet];
    
    NSInteger timeZone =  timeZoneOffset / 3600;
    [result setValue:@(timeZone) forKey:kBDAutoTrackTimeZone];
    
    [result setValue:bd_device_timeZoneName() forKey:kBDAutoTrackTimeZoneName];
#if TARGET_OS_IOS
    [result setValue:[[BDAutoTrack trackWithAppID:appID].identifier identifierForVendor]forKey:kBDAutoTrackVendorID];
#endif
    [result setValue:bd_device_currentRegion() forKey:kBDAutoTrackRegion];
    [result setValue:bd_device_currentSystemLanguage() forKey:kBDAutoTrackLanguage];
    [result setValue:bd_device_resolutionString() forKey:kBDAutoTrackResolution];
    [result setValue:@(bd_device_isJailBroken()) forKey:kBDAutoTrackIsJailBroken];
    
/* sandbox related params */
    [result setValue:bd_sandbox_bundleIdentifier() forKey:kBDAutoTrackPackage];
    [result setValue:bd_sandbox_appDisplayName() forKey:kBDAutoTrackAPPDisplayName];
    [result setValue:bd_sandbox_buildVersion() forKey:kBDAutoTrackAPPBuildVersion];
}

#pragma mark private functions
NSMutableDictionary *build_event_params_if_not_exist(NSMutableDictionary *result) {
    if ([result[kBDAutoTrackEventData] isKindOfClass:[NSMutableDictionary class]]) {
        return result[kBDAutoTrackEventData];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([result[kBDAutoTrackEventData] isKindOfClass:[NSDictionary class]]) {
        [params addEntriesFromDictionary:result[kBDAutoTrackEventData]];
    }
    result[kBDAutoTrackEventData] = params;
    return params;
}

#pragma mark Event Parameters
void bd_addSharedEventParams(NSMutableDictionary *result, NSString *appID) {
    /* ABVersions */
    bd_addABVersions(result, appID);
    
    /* UserUniqueID */
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:appID];
    [result setValue:track.identifier.userUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
    [result setValue:track.identifier.userUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
    /* SSID */
    [result setValue:[track ssID] forKey:kBDAutoTrackSSID];

}

/// Affected event types: UITrack, UserEvent (EventV3, Profile)
void bd_addEventParameters(NSMutableDictionary * result) {
    [result setValue:[[BDAutoTrackSessionHandler sharedHandler] sessionID] forKey:kBDAutoTrackEventSessionID];
    [result setValue:bd_dateNowString() forKey:kBDAutoTrackEventTime];
    [result setValue:bd_milloSecondsInterval() forKey:kBDAutoTrackLocalTimeMS];
    [result setValue:@([BDAutoTrackEnviroment sharedEnviroment].connectionType) forKey:kBDAutoTrackEventNetWork];
}

void bd_addScreenOrientation(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(appID);
    if (settings.screenOrientationEnabled) {
        NSMutableDictionary *params = build_event_params_if_not_exist(result);
        NSString *screenOrientation = [BDAutoTrackApplication shared].screenOrientation;
        [params setValue:screenOrientation forKey:kBDAutoTrackScreenOrientation];
    }
}

void bd_addGPSLocation(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(appID);
    BDAutoTrackApplication *bdapp = [BDAutoTrackApplication shared];
    if (settings.trackGPSLocationEnabled && [bdapp hasAutoTrackGPSLocation]) {
        NSMutableDictionary *params = build_event_params_if_not_exist(result);
        [params setValue:bdapp.autoTrackGeoCoordinateSystem forKey:kBDAutoTrackGeoCoordinateSystem];
        [params setValue:@(bdapp.autoTrackLongitude) forKey:kBDAutoTrackLongitude];
        [params setValue:@(bdapp.autoTrackLatitude) forKey:kBDAutoTrackLatitude];
        return;
    }
    
    if ([bdapp hasGPSLocation]) {
        NSMutableDictionary *params = build_event_params_if_not_exist(result);
        [params setValue:bdapp.geoCoordinateSystem forKey:kBDAutoTrackGeoCoordinateSystem];
        [params setValue:@(bdapp.longitude) forKey:kBDAutoTrackLongitude];
        [params setValue:@(bdapp.latitude) forKey:kBDAutoTrackLatitude];
    }
}

void bd_addABVersions(NSMutableDictionary *result, NSString *appID) {
    /* ABVersions */
    if (bd_remoteSettingsForAppID(appID).abTestEnabled) {
        [result setValue:[BDAutoTrack trackWithAppID:appID].abtestManager.sendableABVersions forKey:kBDAutoTrackABSDKVersion];
    }
}



#pragma mark Network Response
BOOL bd_isValidResponse(NSDictionary * responseDict) {
    if (![responseDict isKindOfClass:[NSDictionary class]] || responseDict.count < 1) {
        return NO;
    }
    NSString *tag = [responseDict vetyped_stringForKey:kBDAutoTrackMagicTag];
    return [tag isEqualToString:BDAutoTrackMagicTag];
}

BOOL bd_isResponseMessageSuccess(NSDictionary *responseDict) {
    if (![responseDict isKindOfClass:[NSDictionary class]] || responseDict.count < 1) {
        return NO;
    }

    NSString *message = [responseDict vetyped_stringForKey:kBDAutoTrackMessage];
    return [message isEqualToString:BDAutoTrackMessageSuccess];
}

void bd_updateServerTime(NSDictionary *responseDict) {
    long long interval = [responseDict vetyped_longlongValueForKey:kBDAutoTrackServerTime];
    if (interval > 0) {
        NSDictionary *timeSyncDicts = @{kBDAutoTrackServerTime: @(interval),
                                        kBDAutoTrackLocalTime: @((long long)(bd_currentIntervalValue()))};
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] setObject:timeSyncDicts forKey:kTimeSyncStorageKey];
        });
    }
}

NSDictionary * bd_timeSync(void) {
    NSDictionary *timeSyncDicts = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kTimeSyncStorageKey];
    if (![timeSyncDicts isKindOfClass:[NSDictionary class]]) {
        long long interval = (long long)bd_currentIntervalValue();
        timeSyncDicts = @{kBDAutoTrackServerTime: @(interval),
                          kBDAutoTrackLocalTime: @(interval)};
    }

    return timeSyncDicts;
}
