//
//  BDAutoTrackConstants.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/5/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackNotifications.h"

NSString * const BDAutoTrackVCSwitchEventNotification   = @"BDAutoTrackVCSwitchEventNotification";

NSString * const kBDAutoTrackViewControllerFormer       = @"kBDAutoTrackViewControllerFormer";
NSString * const kBDAutoTrackViewControllerAfter        = @"kBDAutoTrackViewControllerAfter";
NSString * const kBDAutoTrackSwitchIsBack               = @"kBDAutoTrackSwitchIsBack";

NSString * const BDAutoTrackNotificationRegisterSuccess     = @"BDAutoTrackRegisterSuccess";
NSString * const BDAutoTrackNotificationRegisterFailure     = @"BDAutoTrackRegisterFailure";
NSString * const BDAutoTrackNotificationABTestSuccess       = @"BDAutoTrackABTestSuccess";

NSString * const kBDAutoTrackNotificationAppID              = @"AppID";
NSString * const kBDAutoTrackNotificationRangersDeviceID    = @"RangersDeviceID";
NSString * const kBDAutoTrackNotificationSSID               = @"SSID";
NSString * const kBDAutoTrackNotificationInstallID          = @"InstallID";
NSString * const kBDAutoTrackNotificationUserUniqueID       = @"UserUniqueID";
NSString * const kBDAutoTrackNotificationData               = @"Data";
NSString * const kBDAutoTrackNotificationIsNewUser          = @"isNewUser";

NSString * const kBDAutoTrackNotificationDataSource         = @"dataSource";
BDAutoTrackNotificationDataSource BDAutoTrackNotificationDataSourceLocalCache = @"local_cahce";
BDAutoTrackNotificationDataSource BDAutoTrackNotificationDataSourceServer     = @"server";

NSString * const kBDAutoTrackNotificationDataSourceURL = @"URL";

NSString * const BDAutoTrackNotificationABTestVidsChanged     = @"BDAutoTrackABTesVidsChanged";
NSString * const kBDAutoTrackNotificationABTestVids           = @"applog_vids";
NSString * const kBDAutoTrackNotificationABTestExternalVids   = @"external_vids";
