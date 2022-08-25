//
//  VEInstall.h
//  VEInstall
//
//  Created by KiBen on 2021/9/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "VEInstallConfig.h"
#import "VEInstallRegisterResponse.h"
#import "VEInstallNotificationConstants.h"

NS_ASSUME_NONNULL_BEGIN

/*
 提供Notification的方式获取注册结束状态
 注意：这两个通知只会在请求完成之后回调一次，并且在主线程回调
 
 VEInstallDidRegisterDeviceNotification
 @userinfo:
{
    VEInstallNotificationKeyAppID :AppID,
    VEInstallNotificationKeyRegisterResponse : VEInstallRegisterResponse对象
 }
 */
FOUNDATION_EXTERN NSString *const VEInstallDidRegisterDeviceNotification; // 注册完成通知



@class VEInstall;
@protocol VEInstallObserverProtocol <NSObject>

@optional
/*
 设备注册回调
 */
- (void)install:(VEInstall *)install didRegisterDeviceWithResponse:(VEInstallRegisterResponse *)registerReponse;
- (void)install:(VEInstall *)install didRegisterDeviceFailWithError:(NSError *)error;

@end

@interface VEInstall : NSObject

/// 设备id，标识一台设备，由服务端生成
@property (nonatomic, copy, readonly, nullable) NSString *deviceID;

/// 安装id，卸载重装或更新版本会变化，由服务端生成
@property (nonatomic, copy, readonly, nullable) NSString *installID;

/// 数说id
@property (nonatomic, copy, readonly, nullable) NSString *ssID;

/// 口令
@property (nonatomic, copy, readonly, nullable) NSString *deviceToken;

/// 是否为新用户
@property (nonatomic, assign, readonly) BOOL isNewUser;


@property (nonatomic, copy, readonly, nullable) NSString *cdValue;

/// 初始化VEInstall时传进的VEInstallConfig实例对象
@property (nonatomic, strong, readonly) VEInstallConfig *installConfig;


/// 初始化VEInstall实例
/// @param config 配置实例对象，包含AppID、channel、name等重要参数
- (instancetype)initWithConfig:(VEInstallConfig *)config;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


/// 添加设备注册/激活服务监听者
/// @note 内部对监听者持弱引用；当本地有缓存相关id时，调用此接口会先触发一次
/// install: didRegisterDeviceWithResponse:代理方法回调
/// @param observer 监听者
- (void)addObserver:(id<VEInstallObserverProtocol>)observer;


/// 移除设备注册/激活服务监听者
/// @param observer 监听者
- (void)removeObserver:(id<VEInstallObserverProtocol>)observer;


/// 启动设备注册
/// @note 内部会自动进行设备激活操作，通常无需手动激活
- (void)registerDevice;


/// 用于判断当前设备是否已注册
/// @return 如果已注册，则返回YES，否则，返回NO
- (BOOL)isDeviceRegisted;


/// 清除本地(keychain以及文件)缓存的所有id
- (BOOL)clearAllStorageIDs;

@end

NS_ASSUME_NONNULL_END
