//
//  VEInstallConfig.h
//  VEInstall
//
//  Created by KiBen on 2021/9/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "VEInstallURLService.h"
#import "VEInstallDataEncryptProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString*, id> *_Nullable (^VEInstallCustomParamsBlock)(void);

@interface VEInstallConfig : NSObject

/// ⚠️必传！！！业务方AppID
@property (nonatomic, copy) NSString *appID;


/// ⚠️必传！！！当前App包渠道
@property (nonatomic, copy) NSString *channel;


/// ⚠️必传！！！当前App名称
@property (nonatomic, copy) NSString *name;


/// ⚠️必传！！！当前服务使用的域名；目前提供CN(中国)、SG(新加坡)、VA(美东)
@property (nonatomic, copy) Class<VEInstallURLService> URLService;


/// 当前用户ID
@property (nonatomic, copy, nullable) NSString *userUniqueID;


/// 是否数据加密，默认为YES;
/// @note Debug阶段可设置为NO，方便抓包调试
@property (nonatomic, assign, getter=isEncryptEnable) BOOL encryptEnable;


/// 自定义数据加密器; 默认为nil，则数据不做加密
/// @note 该属性只在encryptEnable设置为YES时生效
@property (nonatomic, copy, nullable) Class<VEInstallDataEncryptProvider> encryptProvider;


/// 请求超时时长；默认为15秒
@property (nonatomic, assign) NSTimeInterval timeoutInterval;


/// 设备注册/激活请求重试次数；默认为3次
@property (nonatomic, assign) NSUInteger retryTimes;


/// 设备注册/激活请求重试时间间隔；默认为5秒
@property (nonatomic, assign) NSTimeInterval retryDuration;


/// 自定义Header中的扩展字段，会单独保存在header中独立的custom字段中
@property (nonatomic, copy, nullable) VEInstallCustomParamsBlock customHeaderBlock;

@end

NS_ASSUME_NONNULL_END
