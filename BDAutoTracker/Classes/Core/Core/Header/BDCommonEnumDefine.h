//
//  BDCommonEnumDefine.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

#ifndef BDCommonEnumDefine_h
#define BDCommonEnumDefine_h

/*! @abstract 日志上报地区属性
 @discussion 上报地区请勿擅自选择，需要与申请服务的地区一致，或者咨询接口人确认
 */
typedef NSString* BDAutoTrackServiceVendor NS_EXTENSIBLE_STRING_ENUM;
FOUNDATION_EXTERN BDAutoTrackServiceVendor const BDAutoTrackServiceVendorPrivate;  // 私有化，此时一定要设置BDAutoTrackRequestURLBlock



/*!
 *  DataType Enum
 */


typedef NS_ENUM(NSUInteger, BDAutoTrackDataType) {
    BDAutoTrackDataTypeUserEvent        = 1 << 0,
    BDAutoTrackDataTypeProfile          = 1 << 1,
    BDAutoTrackDataTypePage             = 1 << 4,
    BDAutoTrackDataTypeClick            = 1 << 5,
    BDAutoTrackDataTypeAll              = ( BDAutoTrackDataTypeUserEvent | BDAutoTrackDataTypeProfile | BDAutoTrackDataTypePage | BDAutoTrackDataTypeClick)
};


/*!
 *  Event Policy
 */
typedef NS_ENUM(NSUInteger, BDAutoTrackEventPolicy) {
    BDAutoTrackEventPolicyAccept        = 1 << 0,
    BDAutoTrackEventPolicyDeny          = 1 << 1,
};


/*!
 请求URL type
 */


typedef NS_ENUM(NSInteger, BDAutoTrackRequestURLType) {
    BDAutoTrackRequestURLRegister   = 0x001,
    BDAutoTrackRequestURLActivate   = 0x002,
    BDAutoTrackRequestURLSettings   = 0x003,
    BDAutoTrackRequestURLABTest     = 0x004,
    BDAutoTrackRequestURLLog        = 0x005,
    BDAutoTrackRequestURLLogBackup  = 0x006,
    BDAutoTrackRequestURLProfile    = 7,

    BDAutoTrackRequestURLSimulatorLogin    = 100,
    BDAutoTrackRequestURLSimulatorUpload   = 101,
    BDAutoTrackRequestURLSimulatorLog      = 102,

    BDAutoTrackRequestURLALinkLinkData        = 200,
    BDAutoTrackRequestURLALinkAttributionData = 201,
};


typedef NS_ENUM(NSUInteger, BDAutoTrackLaunchFrom) {
    /// 初始状态
    BDAutoTrackLaunchFromInitialState = 0,
    /// 用户手动点击进入app
    BDAutoTrackLaunchFromUserClick,
    /// 用户通过push点击进入app
    BDAutoTrackLaunchFromRemotePush,
    /// 用户通过widget点击进入app
    BDAutoTrackLaunchFromWidget,
    /// 用户通过sptlight点击进入app
    BDAutoTrackLaunchFromSpotlight,
    /// 用户通过外部app唤醒进入app
    BDAutoTrackLaunchFromExternal,
    /// 用户手动切回前台
    BDAutoTrackLaunchFromBackground,
    /// from siri
    BDAutoTrackLaunchFromSiri,
};

/**
 IDFA Authorization Status
 */
typedef NS_ENUM(NSInteger, BDAutoTrackAuthorizationStatus) {
    BDAutoTrackAuthorizationStatusNotDetermined = 0,
    BDAutoTrackAuthorizationStatusRestricted,
    BDAutoTrackAuthorizationStatusDenied,
    BDAutoTrackAuthorizationStatusAuthorized
};

/**
 IDFA Authorization Status
 */
typedef NS_ENUM(NSInteger, BDAutoTrackGeoCoordinateSystem) {
    BDAutoTrackGeoCoordinateSystemWGS84 = 1 << 0,
    BDAutoTrackGeoCoordinateSystemGCJ02 = 1 << 1,
    BDAutoTrackGeoCoordinateSystemBD09  = 1 << 2,
    BDAutoTrackGeoCoordinateSystemBDCS  = 1 << 3
};

#endif /* BDCommonEnumDefine_h */
