//
//  BDAutoTrackConstants.h
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/5/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

#ifndef BDAutoTrackNotifictaion_H
#define BDAutoTrackNotifictaion_H

FOUNDATION_EXTERN NSString * const BDAutoTrackVCSwitchEventNotification;

FOUNDATION_EXTERN NSString * const kBDAutoTrackViewControllerFormer;
FOUNDATION_EXTERN NSString * const kBDAutoTrackViewControllerAfter;
FOUNDATION_EXTERN NSString * const kBDAutoTrackSwitchIsBack;

FOUNDATION_EXTERN NSString * const BDAutoTrackNotificationRegisterSuccess;

FOUNDATION_EXTERN NSString * const BDAutoTrackNotificationRegisterFailure;

FOUNDATION_EXTERN NSString * const BDAutoTrackNotificationABTestSuccess;

/*! @abstract SDK通知的userInfo的 key 定义
 若无特别说明，值类型为NSString。
*/
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationAppID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationRangersDeviceID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationSSID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationInstallID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationUserUniqueID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationData;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationIsNewUser;

FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationDataSource;

typedef NSString * const BDAutoTrackNotificationDataSource NS_TYPED_ENUM;
FOUNDATION_EXTERN BDAutoTrackNotificationDataSource BDAutoTrackNotificationDataSourceLocalCache;
FOUNDATION_EXTERN BDAutoTrackNotificationDataSource BDAutoTrackNotificationDataSourceServer;

FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationDataSourceURL;
FOUNDATION_EXTERN NSString * const BDAutoTrackNotificationABTestVidsChanged;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationABTestVids;
FOUNDATION_EXTERN NSString * const kBDAutoTrackNotificationABTestExternalVids;

#endif
