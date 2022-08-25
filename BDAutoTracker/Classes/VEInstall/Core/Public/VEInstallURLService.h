//
//  VEInstallURLService.h
//  Pods
//
//  Created by KiBen on 2021/9/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

#ifndef VEInstallURLService_h
#define VEInstallURLService_h

NS_ASSUME_NONNULL_BEGIN

/// 如果有需要自定义设备注册请求URL，可实现该协议，并将service传给VEInstallConfig.URLServivce参数即可
@protocol VEInstallURLService <NSObject>

+ (NSString *)registerDeviceURLStringForAppID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END

#endif /* VEInstallURLProtocol_h */
