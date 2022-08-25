//
//  BDAutoTrackDeviceHelper.h
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifndef BDAutoTrackDeviceHelper_H
#define BDAutoTrackDeviceHelper_H


/// 设备相关信息

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *ral_base64_string(NSString *base64);
FOUNDATION_EXTERN BOOL bd_device_isJailBroken(void);
FOUNDATION_EXTERN NSString * bd_device_platformName(void);
FOUNDATION_EXTERN NSString * bd_device_machineModel(void);
FOUNDATION_EXTERN BOOL bd_device_isSimulator(void);
FOUNDATION_EXTERN NSString * bd_device_decivceModel(void);
FOUNDATION_EXTERN CGFloat bd_device_screenScale(void);
FOUNDATION_EXTERN NSString * bd_device_resolutionString(void);
FOUNDATION_EXTERN CGSize bd_device_resolution(void);
FOUNDATION_EXTERN NSString * bd_device_currentSystemLanguage(void);
FOUNDATION_EXTERN NSString * bd_device_currentLanguage(void);
FOUNDATION_EXTERN NSString * bd_device_currentRegion(void);
FOUNDATION_EXTERN NSString * bd_device_timeZoneName(void);
FOUNDATION_EXTERN NSInteger bd_device_timeZoneOffset(void);
FOUNDATION_EXTERN NSString * bd_device_systemVersion(void);

FOUNDATION_EXTERN NSString *bd_device_uuid(void) API_AVAILABLE(macos(10.10));
FOUNDATION_EXTERN NSString *bd_device_serial(void) API_AVAILABLE(macos(10.10));
FOUNDATION_EXTERN NSString *bd_device_sku(void) API_AVAILABLE(macos(10.10));

FOUNDATION_EXTERN NSString * bd_device_bootTime(void);
FOUNDATION_EXTERN uint64_t bd_device_physicalMemory(void);
FOUNDATION_EXTERN uint32_t bd_device_cpuCoreCount(void);
FOUNDATION_EXTERN u_int64_t bd_device_totalDiskSpace(void);
FOUNDATION_EXTERN NSString * bd_device_p6(void);

FOUNDATION_EXTERN NSString *bd_device_IPv4(void);

NS_ASSUME_NONNULL_END

#endif
