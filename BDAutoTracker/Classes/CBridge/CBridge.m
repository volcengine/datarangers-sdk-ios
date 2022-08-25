#import <Foundation/Foundation.h>
#import <RangersAppLog/BDAutoTrack.h>
#import "CBridge.h"

static void JSONStrToDictionary(const char *json, NSDictionary **dict) {
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
    NSString *jsonStr = json != NULL ? [NSString stringWithUTF8String:json] : nil;
    if (jsonStr) {
        *dict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    }
}

/// Start RangersAppLog based on some configuation parameters.
/// @param appID appID
/// @param channel channel
/// @param enable_encrypt whether enable paylod encrypt. Note: enable it in production is strongly recommanded.
/// @param enable_log whether enable Logging
/// @param host server host for privatization deployment, e.g.: https://awesomeapp.com/ Pass `NULL` to ignore this.
void ral_start(const char *appID, const char *channel, bool enable_ab, bool enable_encrypt, bool enable_log, const char *host) {
    NSString *_appID = [NSString stringWithCString:appID encoding:NSUTF8StringEncoding];
    NSString *_channel = [NSString stringWithCString:channel encoding:NSUTF8StringEncoding];
    NSString *_host = [NSString stringWithCString:host encoding:NSUTF8StringEncoding];
    
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:_appID launchOptions:nil];
    if (_channel) {
        config.channel = _channel;
    }
    config.abEnable = enable_ab;
    config.showDebugLog = enable_log;
    config.logNeedEncrypt = enable_encrypt;
    [BDAutoTrack startTrackWithConfig:config];
    if (_host) {
        [BDAutoTrack setRequestHostBlock:^NSString * _Nullable(BDAutoTrackServiceVendor  _Nonnull vendor, BDAutoTrackRequestURLType requestURLType) {
         return _host;
         }];
    }
}


/* User */
void ral_set_user_unique_id(const char *user_unique_id) {
    NSString *_ = [NSString stringWithCString:user_unique_id encoding:NSUTF8StringEncoding];
    [[BDAutoTrack sharedTrack] setCurrentUserUniqueID:_];
}

void ral_clear_user_unique_id() {
    [[BDAutoTrack sharedTrack] clearUserUniqueID];
}

char *ral_get_user_unique_id() {
    NSString *uuid = [[BDAutoTrack sharedTrack] userUniqueID];
    const char *p_cstr  = [uuid UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 10240);
    } else {
        return NULL;
    }
}

/* Track */
void ral_track(const char *event, const char *params) {
    NSString *_event = [NSString stringWithCString:event encoding:NSUTF8StringEncoding];
    NSDictionary *_params = nil;
    JSONStrToDictionary(params, &_params);
    [[BDAutoTrack sharedTrack] eventV3:_event params:_params];
}

/* Profile */
void ral_profile_set(const char *properties) {
    NSDictionary *profileProps = nil;
    JSONStrToDictionary(properties, &profileProps);
    [[BDAutoTrack sharedTrack] profileSet:profileProps];
}

void ral_profile_set_once(const char *properties) {
    NSDictionary *profileProps = nil;
    JSONStrToDictionary(properties, &profileProps);
    [[BDAutoTrack sharedTrack] profileSetOnce:profileProps];
}

void ral_profile_unset(const char *prop_name) {
    NSString *propName = [NSString stringWithCString:prop_name encoding:NSUTF8StringEncoding];
    [[BDAutoTrack sharedTrack] profileUnset:propName];
}

void ral_profile_append(const char *properties) {
    NSDictionary *profileProps = nil;
    JSONStrToDictionary(properties, &profileProps);
    [[BDAutoTrack sharedTrack] profileAppend:profileProps];
}

void ral_profile_increment(const char *properties) {
    NSDictionary *profileProps = nil;
    JSONStrToDictionary(properties, &profileProps);
    [[BDAutoTrack sharedTrack] profileIncrement:profileProps];
}


/* Flush */
void ral_flush() {
    [BDAutoTrack flush];
}


/* Custom Header */
void ral_set_custom_header_with_dictionary(const char *dictJSON) {
    NSString *_dictJSON = [NSString stringWithCString:dictJSON encoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[_dictJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingFragmentsAllowed
                                                           error:nil];
    if ([dict isKindOfClass:[NSDictionary class]]) {
        [[BDAutoTrack sharedTrack] setCustomHeaderWithDictionary:dict];
    }
}

void ral_set_custom_header_value_for_key(const char *key, const char *val) {
    NSString *_key = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    NSString *_val = [NSString stringWithCString:val encoding:NSUTF8StringEncoding];
    [[BDAutoTrack sharedTrack] setCustomHeaderValue:_val forKey:_key];
}

void ral_remove_custom_header(const char *key) {
    NSString *_key = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    [[BDAutoTrack sharedTrack] removeCustomHeaderValueForKey:_key];
}


/* AB Test */
/// get exposured Vids
char* ral_get_ab_sdk_version() {
    NSString *allABVids = [[BDAutoTrack sharedTrack] abVids];
    const char *p_cstr  = [allABVids UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 10240);
    } else {
        return NULL;
    }
}

char* ral_get_ab_sdk_version_sync() {
    NSString *allABVids = [[BDAutoTrack sharedTrack] abVidsSync];
    const char *p_cstr  = [allABVids UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 10240);
    } else {
        return NULL;
    }
}

char* ral_get_all_ab_test_config() {
    NSDictionary *_ = [[BDAutoTrack sharedTrack] allABTestConfigs];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_ options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    const char *p_cstr  = [json UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 102400);
    } else {
        return NULL;
    }
}

char* ral_get_all_ab_test_config_sync() {
    NSDictionary *_ = [[BDAutoTrack sharedTrack] allABTestConfigsSync];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_ options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    const char *p_cstr  = [json UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 102400);
    } else {
        return NULL;
    }
}

char* ral_get_all_ab_test_config2(void) {
    NSDictionary *_ = [[BDAutoTrack sharedTrack] allABTestConfigs2];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_ options:NSJSONWritingFragmentsAllowed error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    const char *p_cstr  = [json UTF8String];
    if (p_cstr) {
        return strndup(p_cstr , 102400);
    } else {
        return NULL;
    }
}

char* ral_ab_test_config_value_for_key(const char *key) {
    NSString *_key = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    id obj = [[BDAutoTrack sharedTrack] ABTestConfigValueForKey:_key defaultValue:nil];
    if ([obj isKindOfClass:[NSObject class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingFragmentsAllowed error:nil];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        const char *p_cstr  = [json UTF8String];
        if (p_cstr ) {
            return strndup(p_cstr , 102400);
        } else {
            return NULL;
        }
    }
    
    return NULL;
}

char* ral_ab_test_config_value_sync_for_key(const char *key) {
    NSString *_key = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    id obj = [[BDAutoTrack sharedTrack] ABTestConfigValueSyncForKey:_key defaultValue:nil];
    if ([obj isKindOfClass:[NSObject class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingFragmentsAllowed error:nil];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        const  char *p_cstr  = [json UTF8String];
        if (p_cstr ) {
            return strndup(p_cstr , 102400);
        } else {
            return NULL;
        }
    }
    
    return NULL;
}

void ral_ab_set_external_ab_versions(const char *external_ab_versions) {
    NSString *ex_ab_vers = [NSString stringWithCString:external_ab_versions encoding:NSUTF8StringEncoding];
    [[BDAutoTrack sharedTrack] setExternalABVersion:ex_ab_vers];
}


/* Various IDs */
char* ral_device_id() {
    NSString *deviceID = [[BDAutoTrack sharedTrack] rangersDeviceID];
    const char *p_cstr  = [deviceID UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 1024);
    } else {
        return NULL;
    }
}

char* ral_ssid() {
    NSString *ssid = [[BDAutoTrack sharedTrack] ssID];
    const char *p_cstr  = [ssid UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 1024);
    } else {
        return NULL;
    }
}

char* ral_install_id() {
    NSString *iid = [[BDAutoTrack sharedTrack] installID];
    const char *p_cstr  = [iid UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 1024);
    } else {
        return NULL;
    }
}

char* ral_appid() {
    NSString *aid = [[BDAutoTrack sharedTrack] appID];
    const char *p_cstr  = [aid UTF8String];
    if (p_cstr ) {
        return strndup(p_cstr , 1024);
    } else {
        return NULL;
    }
}

