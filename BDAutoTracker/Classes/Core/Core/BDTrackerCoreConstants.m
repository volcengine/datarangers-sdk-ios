//
//  BDTrackerCoreConstants.m
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

#pragma mark - SDK VERSION Metas
NSString * const kBDAutoTrackerSDKVersion       = @"sdk_version";
NSString * const kBDPickerSDKVersion            = @"bindSdkVersion";
NSString * const kBDAutoTrackerSDKVersionCode   = @"sdk_version_code";
NSString * const kBDAutoTrackerVersionCode      = @"version_code";

NSInteger const BDAutoTrackerSDKMajorVersion = 6;
NSInteger const BDAutoTrackerSDKMinorVersion = 10;
NSInteger const BDAutoTrackerSDKPatchVersion = 2;
NSInteger const BDAutoTrackerSDKVersion      = BDAutoTrackerSDKMajorVersion * 10000 +
                                               BDAutoTrackerSDKMinorVersion * 100 +
                                               BDAutoTrackerSDKPatchVersion;
NSInteger const BDAutoTrackerSDKVersionCode = 10000000 + BDAutoTrackerSDKVersion;


#pragma mark - magic tag
// 顶层键
NSString * const kBDAutoTrackMagicTag               = @"magic_tag";
NSString * const BDAutoTrackMagicTag                = @"ss_app_log";


#pragma mark - time_sync
// 顶层键
// 也是服务器响应和UserDefaults存储中的键。
NSString * const kBDAutoTrackTimeSync               = @"time_sync";
NSString * const kBDAutoTrackServerTime             = @"server_time";
NSString * const kBDAutoTrackLocalTime              = @"local_time";

#pragma mark - event_v3 事件上报键名
// 事件名
NSString * const kBDAutoTrackEventType              = @"event";
// 事件数据
NSString * const kBDAutoTrackEventData              = @"params";
// kBDAutoTrackEventTime和kBDAutoTrackEventTime都是即将通过网络上报事件时的时刻。
// 两者均为独立生成，一般会有微小差别。
NSString * const kBDAutoTrackEventTime              = @"datetime";
NSString * const kBDAutoTrackLocalTimeMS            = @"local_time_ms";
// BDAutoTrackNetworkConnectionType. 4代表是WiFi网络，5代表是4G网络
NSString * const kBDAutoTrackEventNetWork           = @"nt";
NSString * const kBDAutoTrackEventSessionID         = @"session_id";
NSString * const kBDAutoTrackEventUserID            = @"user_unique_id";
NSString * const kBDAutoTrackEventUserIDType        = @"$user_unique_id_type";

NSString * const kBDAutoTrackGlobalEventID          = @"tea_event_index";
// 标记Launch、Terminate事件是否是被动启动。
NSString * const kBDAutoTrackIsBackground           = @"is_background";
// 标记Launch事件是否是从后台恢复产生的，false是冷启动，true是热启动
NSString * const kBDAutoTrackResumeFromBackground   = @"$resume_from_background";

#pragma mark - header 各键名

// 顶层键
NSString * const kBDAutoTrackHeader                 = @"header";
NSString * const kBDAutoTrackTracerData             = @"tracer_data";

// custom键，值是一个custom数组。touch_point也在custom键下。
NSString * const kBDAutoTrackCustom                 = @"custom";
NSString * const kBDAutoTrackTouchPoint             = @"touch_point"; // 用户触点。custom header field, set by user
NSString * const kBDAutoTrack__tr_web_ssid          = @"$tr_web_ssid";

NSString * const kBDAutoTrackDeviceID               = @"device_id";
NSString * const kBDAutoTrackBDDeviceID             = @"bd_did";
NSString * const kBDAutoTrackCD                     = @"cd";
NSString * const kBDAutoTrackInstallID              = @"install_id";
NSString * const kBDAutoTrackSSID                   = @"ssid";  // 数说ID

NSString * const kBDAutoTrackAPPID                  = @"aid";
NSString * const kBDAutoTrackAPPName                = @"app_name";
NSString * const kBDAutoTrackAPPDisplayName         = @"display_name";
NSString * const kBDAutoTrackChannel                = @"channel";
NSString * const kBDAutoTrackABSDKVersion           = @"ab_sdk_version";
NSString * const kBDAutoTrackIsFirstTime            = @"$is_first_time";  // 事件参数 - 首次触发标记. 标志一个用户的首次Launch事件。
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
NSString * const kBDAutoTrackDecivcePlatform        = @"device_platform"; // used to generate UserAgent
NSString * const kBDAutoTrackPlatform               = @"platform";
NSString * const kBDAutoTrackSDKLib                 = @"sdk_lib";

NSString * const kBDAutoTrackResolution             = @"resolution";
NSString * const kBDAutoTrackTimeZone               = @"timezone";
NSString * const kBDAutoTrackAccess                 = @"access";
NSString * const kBDAutoTrackAPPVersion             = @"app_version";
NSString * const kBDAutoTrackAPPBuildVersion        = @"app_version_minor";
NSString * const kBDAutoTrackPackage                = @"package";
NSString * const kBDAutoTrackCarrier                = @"carrier";
NSString * const kBDAutoTrackMCCMNC                 = @"mcc_mnc";
NSString * const kBDAutoTrackRegion                 = @"region";
NSString * const kBDAutoTrackAppRegion              = @"app_region";
NSString * const kBDAutoTrackTimeZoneName           = @"tz_name";
NSString * const kBDAutoTrackTimeZoneOffSet         = @"tz_offset";
NSString * const kBDAutoTrackIdentifierForTracking  = @"idfa";
NSString * const kBDAutoTrackVendorID               = @"vendor_id";
NSString * const kBDAutoTrackIsJailBroken           = @"is_jailbroken";
NSString * const kBDAutoTrackIsUpgradeUser          = @"is_upgrade_user";
NSString * const kBDAutoTrackUserAgent              = @"user_agent";

NSString * const kBDAutoTrackLinkType               = @"$link_type";    // ALink 唤醒类型
NSString * const kBDAutoTrackDeepLinkUrl            = @"$deeplink_url"; // ALink 的 deepLinkUrl

// 屏幕方向
NSString * const kBDAutoTrackScreenOrientation      = @"$screen_orientation";

// GPS
NSString * const kBDAutoTrackGeoCoordinateSystem      = @"$geo_coordinate_system";
NSString * const kBDAutoTrackLongitude                = @"$longitude";
NSString * const kBDAutoTrackLatitude                 = @"$latitude";

// 时长统计
NSString * const kBDAutoTrackEventDuration                 = @"$event_duration";

#pragma mark - iOS 14应对工作新增参数 (header)
// 目前只是注册请求header中携带
// 本地时区
NSString * const kBDAutoTrackLocalTZName            = @"local_tz_name";
// 手机开机时间
NSString * const kBDAutoTrackBootTime               = @"boot_time";
// 系统版本更新时间
NSString * const kBDAutoTrackMBTime                 = @"mb_time";
// CPU 核数
NSString * const kBDAutoTrackCPUNum                 = @"cpu_num";
// 系统磁盘空间
NSString * const kBDAutoTrackDiskMemory             = @"disk_total";
// 系统总内存空间
NSString * const kBDAutoTrackPhysicalMemory         = @"mem_total";

#pragma mark - macOS Identifier
//MacOS UUID
NSString * const kBDAutoTrackMacOSUUID              = @"macos_uuid";
//设备序列号
NSString * const kBDAutoTrackMacOSSerial            = @"macos_serial";
//设备硬件型号
NSString * const kBDAutoTrackSku                    = @"sku";


#pragma mark - query Key
// 注：有一些键既在header中，也在query中，比如aid。
NSString * const kBDAutoTrackTTInfo                 = @"tt_info"; // query key of a encrypted query data
NSString * const kBDAutoTrackTTData                 = @"tt_data"; // indicator of the existence of an encrypted query


#pragma mark - 服务器响应
NSString * const kBDAutoTrackMessage                = @"message";
NSString * const BDAutoTrackMessageSuccess          = @"success";
NSString * const kBDAutoTrackRequestHTTPCode        = @"status_code";


#pragma mark - BDAutoTrackDefaults keys
/* Local Config Service */
NSString * const kBDAutoTrackConfigAppTouchPoint = @"kBDAutoTrackConfigAppTouchPoint";
NSString * const kBDAutoTrackConfigAppLanguage   = @"kBDAutoTrackConfigAppLanguage";
NSString * const kBDAutoTrackConfigAppRegion     = @"kBDAutoTrackConfigAppRegion";
NSString * const kBDAutoTrackConfigUserUniqueID  = @"kBDAutoTrackConfigUserUniqueID";
NSString * const kBDAutoTrackConfigUserUniqueIDType  = @"kBDAutoTrackConfigUserUniqueIDType";
NSString * const kBDAutoTrackConfigUserAgent     = @"kBDAutoTrackConfigUserAgent";

/* 用户维度的首次启动标记 */
NSString *const kBDAutoTrackIsFirstTimeLaunch    = @"kBDAutoTrackIsFirstTimeLaunch";  // 有效值: nil, "false"
/*! 应用维度的首次启动标记 */
NSString *const kBDAutoTrackIsAPPFirstTimeLaunch = @"kBDAutoTrackIsAPPFirstTimeLaunch";  // 有效值: nil, "false"

#pragma mark - h5bridge
NSString * const rangersapplog_script_message_handler_name = @"rangersapplog_ios_h5bridge_message_handler";
