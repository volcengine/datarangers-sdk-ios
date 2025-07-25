//
//  BDTrackerCoreConstants.m
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

NSString * const kBDAutoTrackerSDKVersion       = @"sdk_version";
NSString * const kBDPickerSDKVersion            = @"bindSdkVersion";
NSString * const kBDAutoTrackerSDKVersionCode   = @"sdk_version_code";
NSString * const kBDAutoTrackerVersionCode      = @"version_code";

NSInteger const BDAutoTrackerSDKMajorVersion = 6;
NSInteger const BDAutoTrackerSDKMinorVersion = 17;
NSInteger const BDAutoTrackerSDKPatchVersion = 4;
NSInteger const BDAutoTrackerSDKVersion      = BDAutoTrackerSDKMajorVersion * 10000 +
                                               BDAutoTrackerSDKMinorVersion * 100 +
                                               BDAutoTrackerSDKPatchVersion;
NSInteger const BDAutoTrackerSDKVersionCode = 10000000 + BDAutoTrackerSDKVersion;

NSString * const kBDAutoTrackMagicTag               = @"magic_tag";
NSString * const BDAutoTrackMagicTag                = @"ss_app_log";

NSString * const kBDAutoTrackTimeSync               = @"time_sync";
NSString * const kBDAutoTrackServerTime             = @"server_time";
NSString * const kBDAutoTrackLocalTime              = @"local_time";

NSString * const kBDAutoTrackEventType              = @"event";
NSString * const kBDAutoTrackEventData              = @"params";
NSString * const kBDAutoTrackEventTime              = @"datetime";
NSString * const kBDAutoTrackLocalTimeMS            = @"local_time_ms";
NSString * const kBDAutoTrackEventNetWork           = @"nt";
NSString * const kBDAutoTrackEventSessionID         = @"session_id";
NSString * const kBDAutoTrackEventUserID            = @"user_unique_id";
NSString * const kBDAutoTrackEventUserIDType        = @"$user_unique_id_type";

NSString * const kBDAutoTrackGlobalEventID          = @"tea_event_index";
NSString * const kBDAutoTrackIsBackground           = @"is_background";
NSString * const kBDAutoTrackResumeFromBackground   = @"$resume_from_background";

NSString * const kBDAutoTrackHeader                 = @"header";
NSString * const kBDAutoTrackTracerData             = @"tracer_data";

NSString * const kBDAutoTrackCustom                 = @"custom";
NSString * const kBDAutoTrackTouchPoint             = @"touch_point";
NSString * const kBDAutoTrack__tr_web_ssid          = @"$tr_web_ssid";

NSString * const kBDAutoTrackBDDid                  = @"bd_did";
NSString * const kBDAutoTrackCD                     = @"cd";
NSString * const kBDAutoTrackInstallID              = @"install_id";
NSString * const kBDAutoTrackSSID                   = @"ssid";

NSString * const kBDAutoTrackAPPID                  = @"aid";
NSString * const kBDAutoTrackAPPName                = @"app_name";
NSString * const kBDAutoTrackAPPDisplayName         = @"display_name";
NSString * const kBDAutoTrackChannel                = @"channel";
NSString * const kBDAutoTrackABSDKVersion           = @"ab_sdk_version";
NSString * const kBDAutoTrackIsFirstTime            = @"$is_first_time";
NSString * const kBDAutoTrackLanguage               = @"language";
NSString * const kBDAutoTrackAppLanguage            = @"app_language";

NSString * const kBDAutoTrackOS                     = @"os";
#if TARGET_OS_IOS
NSString * const BDAutoTrackOSName                     = @"iOS";
#elif TARGET_OS_OSX
NSString * const BDAutoTrackOSName                     = @"MacOS";
#endif
NSString * const kBDAutoTrackOSVersion              = @"os_version";
NSString * const kBDAutoTrackDecivceModel           = @"device_model";
NSString * const kBDAutoTrackDecivcePlatform        = @"device_platform";
NSString * const kBDAutoTrackPlatform               = @"platform";
NSString * const kBDAutoTrackSDKLib                 = @"sdk_lib";

NSString * const kBDAutoTrackResolution             = @"resolution";
NSString * const kBDAutoTrackTimeZone               = @"timezone";
NSString * const kBDAutoTrackAccess                 = @"access";
NSString * const kBDAutoTrackAPPVersion             = @"app_version";
NSString * const kBDAutoTrackAPPVersion2            = @"$app_version";
NSString * const kBDAutoTrackAPPBuildVersion        = @"app_version_minor";
NSString * const kBDAutoTrackPackage                = @"package";
NSString * const kBDAutoTrackRegion                 = @"region";
NSString * const kBDAutoTrackAppRegion              = @"app_region";
NSString * const kBDAutoTrackTimeZoneName           = @"tz_name";
NSString * const kBDAutoTrackTimeZoneOffSet         = @"tz_offset";
NSString * const kBDAutoTrackVendorID               = @"vendor_id";
NSString * const kBDAutoTrackIsUpgradeUser          = @"is_upgrade_user";
NSString * const kBDAutoTrackUserAgent              = @"user_agent";

NSString * const kBDAutoTrackLinkType               = @"$link_type";
NSString * const kBDAutoTrackDeepLinkUrl            = @"$deeplink_url";

NSString * const kBDAutoTrackScreenOrientation      = @"$screen_orientation";

NSString * const kBDAutoTrackGeoCoordinateSystem      = @"$geo_coordinate_system";
NSString * const kBDAutoTrackLongitude                = @"$longitude";
NSString * const kBDAutoTrackLatitude                 = @"$latitude";

NSString * const kBDAutoTrackEventDuration                 = @"$event_duration";

NSString * const kBDAutoTrackLocalTZName            = @"local_tz_name";
NSString * const kBDAutoTrackBootTime               = @"boot_time";
NSString * const kBDAutoTrackMBTime                 = @"mb_time";
NSString * const kBDAutoTrackCPUNum                 = @"cpu_num";
NSString * const kBDAutoTrackDiskMemory             = @"disk_total";
NSString * const kBDAutoTrackPhysicalMemory         = @"mem_total";

NSString * const kBDAutoTrackMacOSUUID              = @"macos_uuid";
NSString * const kBDAutoTrackMacOSSerial            = @"macos_serial";
NSString * const kBDAutoTrackSku                    = @"sku";

NSString * const kBDAutoTrackTTInfo                 = @"tt_info";
NSString * const kBDAutoTrackTTData                 = @"tt_data";

NSString * const kBDAutoTrackMessage                = @"message";
NSString * const BDAutoTrackMessageSuccess          = @"success";
NSString * const kBDAutoTrackRequestHTTPCode        = @"status_code";



NSString * const kBDAutoTrackConfigSSID          = @"kBDAutoTrackConfigSSID";
NSString * const kBDAutoTrackConfigAppTouchPoint = @"kBDAutoTrackConfigAppTouchPoint";
NSString * const kBDAutoTrackConfigAppLanguage   = @"kBDAutoTrackConfigAppLanguage";
NSString * const kBDAutoTrackConfigAppRegion     = @"kBDAutoTrackConfigAppRegion";
NSString * const kBDAutoTrackConfigUserUniqueID  = @"kBDAutoTrackConfigUserUniqueID";
NSString * const kBDAutoTrackConfigUserUniqueIDEncode  = @"kBDAutoTrackConfigUserUniqueIDEncode";
NSString * const kBDAutoTrackConfigUserUniqueIDType  = @"kBDAutoTrackConfigUserUniqueIDType";
NSString * const kBDAutoTrackConfigUserAgent     = @"kBDAutoTrackConfigUserAgent";


NSString *const kBDAutoTrackIsFirstTimeLaunch    = @"kBDAutoTrackIsFirstTimeLaunch";
NSString *const kBDAutoTrackIsAPPFirstTimeLaunch = @"kBDAutoTrackIsAPPFirstTimeLaunch";

#pragma mark - h5bridge
NSString * const rangersapplog_script_message_handler_name = @"rangersapplog_ios_h5bridge_message_handler";
