//
//  BDTrackerCoreConstants.h
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDCommonEnumDefine.h"
#import "BDAutoTrackTableConstants.h"

#ifndef BDTrackerCoreConstants_H
#define BDTrackerCoreConstants_H

FOUNDATION_EXTERN NSString * const kBDPickerSDKVersion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackerVersionCode;

FOUNDATION_EXTERN NSInteger  const BDAutoTrackerSDKMajorVersion;
FOUNDATION_EXTERN NSInteger  const BDAutoTrackerSDKMinorVersion;
FOUNDATION_EXTERN NSInteger  const BDAutoTrackerSDKPatchVersion;

FOUNDATION_EXTERN NSString * const kBDAutoTrackerSDKVersion;
FOUNDATION_EXTERN NSInteger  const  BDAutoTrackerSDKVersion;

FOUNDATION_EXTERN NSString * const kBDAutoTrackerSDKVersionCode;
FOUNDATION_EXTERN NSInteger  const  BDAutoTrackerSDKVersionCode;

FOUNDATION_EXTERN NSString * const kBDAutoTrackEventType;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventData;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackLocalTimeMS;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventNetWork;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventSessionID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventUserID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventUserIDType;
FOUNDATION_EXTERN NSString * const kBDAutoTrackGlobalEventID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIsBackground;
FOUNDATION_EXTERN NSString * const kBDAutoTrackResumeFromBackground;

FOUNDATION_EXTERN NSString * const kBDAutoTrackDeviceID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackBDDeviceID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackCD;
FOUNDATION_EXTERN NSString * const kBDAutoTrackInstallID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackSSID;

FOUNDATION_EXTERN NSString * const kBDAutoTrackAPPID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAPPName;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAPPDisplayName;
FOUNDATION_EXTERN NSString * const kBDAutoTrackChannel;
FOUNDATION_EXTERN NSString * const kBDAutoTrackABSDKVersion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIsFirstTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackLanguage;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAppLanguage;
FOUNDATION_EXTERN NSString * const kBDAutoTrackCustom;

FOUNDATION_EXTERN NSString * const kBDAutoTrackOS;
FOUNDATION_EXTERN NSString * const BDAutoTrackOSName;
FOUNDATION_EXTERN NSString * const kBDAutoTrackOSVersion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDecivceModel;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDecivcePlatform;
FOUNDATION_EXTERN NSString * const kBDAutoTrackPlatform;
FOUNDATION_EXTERN NSString * const kBDAutoTrackSDKLib;

FOUNDATION_EXTERN NSString * const kBDAutoTrackMacOSUUID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackMacOSSerial;
FOUNDATION_EXTERN NSString * const kBDAutoTrackSku;

FOUNDATION_EXTERN NSString * const kBDAutoTrackResolution;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTimeZone;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAccess;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAPPVersion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAPPBuildVersion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackPackage;
FOUNDATION_EXTERN NSString * const kBDAutoTrackCarrier;
FOUNDATION_EXTERN NSString * const kBDAutoTrackMCCMNC;
FOUNDATION_EXTERN NSString * const kBDAutoTrackRegion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackAppRegion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTimeZoneName;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTimeZoneOffSet;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIdentifierForTracking;
FOUNDATION_EXTERN NSString * const kBDAutoTrackVendorID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIsJailBroken;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIsUpgradeUser;
FOUNDATION_EXTERN NSString * const kBDAutoTrackUserAgent;
FOUNDATION_EXTERN NSString * const kBDAutoTrackServerTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackLocalTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackMagicTag;
FOUNDATION_EXTERN NSString * const BDAutoTrackMagicTag;
FOUNDATION_EXTERN NSString * const kBDAutoTrackMessage;
FOUNDATION_EXTERN NSString * const BDAutoTrackMessageSuccess;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTTInfo;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTTData;

FOUNDATION_EXTERN NSString * const kBDAutoTrackTouchPoint;
FOUNDATION_EXTERN NSString * const kBDAutoTrack__tr_web_ssid;

FOUNDATION_EXTERN NSString * const kBDAutoTrackHeader;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTracerData;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTimeSync;

FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigAppTouchPoint;

FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigAppLanguage;
FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigAppRegion;
FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigUserUniqueID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigUserUniqueIDType;
FOUNDATION_EXTERN NSString * const kBDAutoTrackConfigUserAgent;

FOUNDATION_EXTERN NSString * const kBDAutoTrackRequestHTTPCode;

FOUNDATION_EXTERN NSString * const kBDAutoTrackLocalTZName;
FOUNDATION_EXTERN NSString * const kBDAutoTrackBootTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackMBTime;
FOUNDATION_EXTERN NSString * const kBDAutoTrackCPUNum;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDiskMemory;
FOUNDATION_EXTERN NSString * const kBDAutoTrackPhysicalMemory;


FOUNDATION_EXTERN NSString * const kBDAutoTrackIsFirstTimeLaunch;
FOUNDATION_EXTERN NSString * const kBDAutoTrackIsAPPFirstTimeLaunch;

FOUNDATION_EXTERN NSString * const kBDAutoTrackLinkType;
FOUNDATION_EXTERN NSString * const kBDAutoTrackDeepLinkUrl;

// 屏幕方向
FOUNDATION_EXTERN NSString * const kBDAutoTrackScreenOrientation;

// GPS
FOUNDATION_EXTERN NSString * const kBDAutoTrackGeoCoordinateSystem;
FOUNDATION_EXTERN NSString * const kBDAutoTrackLongitude;
FOUNDATION_EXTERN NSString * const kBDAutoTrackLatitude;

// 时长统计
FOUNDATION_EXTERN NSString * const kBDAutoTrackEventDuration;

#pragma mark - h5bridge
FOUNDATION_EXTERN NSString * const rangersapplog_script_message_handler_name;

#endif
