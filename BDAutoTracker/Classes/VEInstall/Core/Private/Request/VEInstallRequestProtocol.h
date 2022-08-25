//
//  VEInstallRequestProtocol.h
//  Pods
//
//  Created by KiBen on 2021/9/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "VEInstallDataEncryptProvider.h"

#ifndef VEInstallRequestProtocol_h
#define VEInstallRequestProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol VEInstallRequestProtocol <NSObject>

@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) BOOL encryptEnable;
@property (nonatomic, copy, nullable) Class<VEInstallDataEncryptProvider> encryptProvider;

- (void)jsonRequestWithURLString:(NSString *)URLString parameters:(nullable NSDictionary *)parameter success:(nullable void(^)(NSDictionary *_Nonnull result))success failure:(nullable void (^)(NSError *error))failure;

- (void)queryEncodeRequestWithURLString:(NSString *)URLString parameters:(nullable NSDictionary *)parameter success:(nullable void(^)(NSDictionary *_Nonnull result))success failure:(nullable void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END

#endif /* VEInstallRequestProtocol_h */
