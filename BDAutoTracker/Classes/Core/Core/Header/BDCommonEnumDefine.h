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

typedef NSString* BDAutoTrackServiceVendor NS_EXTENSIBLE_STRING_ENUM;
FOUNDATION_EXTERN BDAutoTrackServiceVendor const BDAutoTrackServiceVendorPrivate;

typedef NS_ENUM(NSUInteger, BDAutoTrackDataType) {
    BDAutoTrackDataTypeUserEvent        = 1 << 0,
    BDAutoTrackDataTypeProfile          = 1 << 1,
    BDAutoTrackDataTypeLaunch           = 1 << 2,
    BDAutoTrackDataTypeTerminate        = 1 << 3,
    BDAutoTrackDataTypePageLeave        = 1 << 4,
    BDAutoTrackDataTypePage             = 1 << 5,
    BDAutoTrackDataTypeClick            = 1 << 6,
    BDAutoTrackDataTypeAll              = ( BDAutoTrackDataTypeUserEvent | BDAutoTrackDataTypeProfile | BDAutoTrackDataTypePageLeave | BDAutoTrackDataTypePage | BDAutoTrackDataTypeClick)
};

typedef NS_ENUM(NSUInteger, BDAutoTrackEventStatus) {
    BDAutoTrackEventStatusCreated          = 1 << 0,
    BDAutoTrackEventStatusSaved            = 1 << 1,
    BDAutoTrackEventStatusSaveFailed       = 1 << 2,
    BDAutoTrackEventStatusReported         = 1 << 3,
};

typedef NS_ENUM(NSUInteger, BDAutoTrackEventAllType) {
    BDAutoTrackEventAllTypeUnknown            = 1 << 0,
    BDAutoTrackEventAllTypeLaunch             = 1 << 1,
    BDAutoTrackEventAllTypeTerminate          = 1 << 2,
    BDAutoTrackEventAllTypeProfile            = 1 << 3,
    BDAutoTrackEventAllTypeEventV3            = 1 << 4,
    BDAutoTrackEventAllTypeUIEvent            = 1 << 5,
};

typedef NS_ENUM(NSUInteger, BDAutoTrackEventPolicy) {
    BDAutoTrackEventPolicyAccept        = 1 << 0,
    BDAutoTrackEventPolicyDeny          = 1 << 1,
};

typedef NS_ENUM(NSInteger, BDAutoTrackRequestURLType) {
    BDAutoTrackRequestURLRegister   = 0x001,
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
    
    BDAutoTrackRequestURLOneIDBind = 210,
    
    BDAutoTrackRequestURLABTestLocalShuntVersionInfo = 211,
    
};


typedef NS_ENUM(NSUInteger, BDAutoTrackLaunchFrom) {
    BDAutoTrackLaunchFromInitialState = 0,
    BDAutoTrackLaunchFromUserClick,
    BDAutoTrackLaunchFromRemotePush,
    BDAutoTrackLaunchFromWidget,
    BDAutoTrackLaunchFromSpotlight,
    BDAutoTrackLaunchFromExternal,
    BDAutoTrackLaunchFromBackground,
    BDAutoTrackLaunchFromSiri,
};

typedef NS_ENUM(NSInteger, BDAutoTrackGeoCoordinateSystem) {
    BDAutoTrackGeoCoordinateSystemWGS84 = 1 << 0,
    BDAutoTrackGeoCoordinateSystemGCJ02 = 1 << 1,
    BDAutoTrackGeoCoordinateSystemBD09  = 1 << 2,
    BDAutoTrackGeoCoordinateSystemBDCS  = 1 << 3
};

typedef NS_ENUM(NSInteger, BDAutoTrackEncryptionType) {
    BDAutoTrackEncryptionTypeDefault = 1 << 0,
};

#endif
