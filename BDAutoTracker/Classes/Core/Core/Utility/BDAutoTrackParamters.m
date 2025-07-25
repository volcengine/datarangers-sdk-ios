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
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackApplication.h"

#if DEBUG && __has_include("RALInstallExtraParams.h")
#import "RALInstallExtraParams.h"
#endif

#import "NSDictionary+VETyped.h"
#import "NSData+VECompression.h"
#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrack+Private.h"

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

#pragma mark Network Parameters
NSMutableDictionary * bd_headerField(NSString *appID) {
    NSMutableDictionary *headerFiled = [NSMutableDictionary new];
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    
    [headerFiled addEntriesFromDictionary:tracker.config.HTTPHeaderFields?:@{}];
    if (tracker.config.setHTTPHeaderFieldsBlock) {
        [headerFiled addEntriesFromDictionary:tracker.config.setHTTPHeaderFieldsBlock()?:@{}];
    }

    [headerFiled setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerFiled setValue:@"application/json" forKey:@"Accept"];
    [headerFiled setValue:@"keep-alive" forKey:@"Connection"];
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
    [result setValue:@(bd_sandbox_isUpgradeUser()) forKey:kBDAutoTrackIsUpgradeUser];
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    NSString *unique = tracker.identifier.advertisingID;
}

void bd_addQueryNetworkParams(NSMutableDictionary *result, NSString *appID) {
    addSharedNetworkParams(result, appID);
#if TARGET_OS_IOS
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    [result setValue:tracker.identifier.vendorID forKey:@"idfv"];
#endif
    [result setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackerVersionCode];
}

void bd_addBodyNetworkParams(NSMutableDictionary *result, NSString *appID) {
    addSharedNetworkParams(result, appID);
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    
    [result setValue:[BDAutoTrackEnviroment sharedEnviroment].connectionTypeName forKey:kBDAutoTrackAccess];
    
    NSInteger timeZoneOffset = bd_device_timeZoneOffset();
    [result setValue:@(timeZoneOffset) forKey:kBDAutoTrackTimeZoneOffSet];
    
    NSInteger timeZone =  timeZoneOffset / 3600;
    [result setValue:@(timeZone) forKey:kBDAutoTrackTimeZone];
    
    [result setValue:bd_device_timeZoneName() forKey:kBDAutoTrackTimeZoneName];
#if TARGET_OS_IOS
    [result setValue:tracker.identifier.vendorID forKey:kBDAutoTrackVendorID];
#endif
    [result setValue:bd_device_currentRegion() forKey:kBDAutoTrackRegion];
    [result setValue:bd_device_currentSystemLanguage() forKey:kBDAutoTrackLanguage];
    [result setValue:bd_device_resolutionString() forKey:kBDAutoTrackResolution];
    
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
    bd_addABVersions(result, appID);
    
    BDAutoTrackLocalConfigService *settings = [BDAutoTrack trackWithAppID:appID].localConfig;
    [result setValue:settings.syncUserUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
    [result setValue:settings.syncUserUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
    [result setValue:bd_registerSSID(appID) forKey:kBDAutoTrackSSID];
    
}

void bd_addEventParameters(NSMutableDictionary * result) {
    [result setValue:[[BDAutoTrackSessionHandler sharedHandler] sessionID] forKey:kBDAutoTrackEventSessionID];
    [result setValue:bd_dateNowString() forKey:kBDAutoTrackEventTime];
    [result setValue:bd_milloSecondsInterval() forKey:kBDAutoTrackLocalTimeMS];
    [result setValue:@([BDAutoTrackEnviroment sharedEnviroment].connectionType) forKey:kBDAutoTrackEventNetWork];
}

void bd_addScreenOrientation(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = [BDAutoTrack trackWithAppID:appID].localConfig;
    if (settings.screenOrientationEnabled) {
        NSMutableDictionary *params = build_event_params_if_not_exist(result);
        NSString *screenOrientation = [BDAutoTrackApplication shared].screenOrientation;
        [params setValue:screenOrientation forKey:kBDAutoTrackScreenOrientation];
    }
}

void bd_addGPSLocation(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackLocalConfigService *settings = [BDAutoTrack trackWithAppID:appID].localConfig;
    if (settings.trackGPSLocationEnabled) {
        BDAutoTrackApplication *bdapp = [BDAutoTrackApplication shared];
        if ([bdapp hasAutoTrackGPSLocation]) {
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
}

void bd_addAppVersion(NSMutableDictionary *result) {
    NSMutableDictionary *params = build_event_params_if_not_exist(result);
    [params setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion2];
}

void bd_addABVersions(NSMutableDictionary *result, NSString *appID) {
    BDAutoTrackABConfig * config = [BDAutoTrack trackWithAppID:appID].abTester;
    
    [result setValue:[config allExposedABVersions] forKey:kBDAutoTrackABSDKVersion];
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

NSDictionary* bd_filterSensitiveParameters(NSDictionary *body, NSString *appID) {
    NSArray *fields = bd_remoteSettingsForAppID(appID).sensitiveFields;
    if (fields && fields.count > 0) {
        
        NSMutableDictionary *modifiedHeader = [[body vetyped_dictionaryForKey:@"header"] mutableCopy];
        __block BOOL modified = NO;
        [modifiedHeader.allKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([fields containsObject:key]) {
                [modifiedHeader removeObjectForKey:key];
                modified = YES;
            }
        }];
        if (modified) {
            NSMutableDictionary *mutableBody = body.mutableCopy;
            [mutableBody setValue:modifiedHeader forKey:@"header"];
            return mutableBody;   
        }
    }
    return body;
}

void bd_handleCommonParamters(NSDictionary *body, BDAutoTrack *tracker, BDAutoTrackRequestURLType requestURLType) {
    BDAutoTrackLocalConfigService *localConfig = tracker.localConfig;
    if (!localConfig.commonParamtersBlock) {
        return;
    }
    
    NSMutableDictionary *header = [[body vetyped_dictionaryForKey:kBDAutoTrackHeader] mutableCopy];
    if (!header) {
        return;
    }
    
    NSDictionary *commonParamters = localConfig.commonParamtersBlock(localConfig.serviceVendor, requestURLType, header);
    if (!commonParamters) {
        return;
    }
    
    [body setValue:commonParamters forKey:kBDAutoTrackHeader];
}
