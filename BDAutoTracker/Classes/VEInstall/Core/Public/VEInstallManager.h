//
//  VEInstallManager.h
//  VEInstall
//
//  Created by KiBen on 2021/9/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "VEInstall.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallConfig (Singleton)

/// 创建全局单例installConfig对象
/// @note ⚠️注意：避免将该对象传进VEInstallManager.createInstallWithConfig，造成install实例对象覆盖问题
+ (instancetype)sharedInstance;

@end

/// VEInstallManager类主要用于创建和维护不同AppID所对应的不同VEInstall实例
/// @note 对于直接使用VEInstall.initWithConfig接口创建的实例，不受VEInstallManager管理
@interface VEInstallManager : NSObject


/// 返回默认的install单例对象，方便单实例场景使用
/// @note ⚠️ 调用此接口时，必须要先调用[VEInstallConfig sharedInstance]配置相关必要参数(AppID、Channel等)。
+ (VEInstall *_Nullable)defaultInstall;


/// 创建install实例对象
/// @param config 配置信息
+ (VEInstall *)createInstallWithConfig:(VEInstallConfig *)config;


/// 返回AppID所对应的缓存install实例对象，适合多实例场景使用
/// @note 如果当前没有缓存AppID对应的install实例，则返回nil；
/// 需要先调用[VEInstallManager createInstallWithConfig:]进行创建
/// @param appID 当前场景下的AppID
+ (VEInstall *_Nullable)installForAppID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
