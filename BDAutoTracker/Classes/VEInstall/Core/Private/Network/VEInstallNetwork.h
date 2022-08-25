//
//  VEInstallNetwork.h
//
//  Created by KiBen on 2019/9/18.
//
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

#import <Foundation/Foundation.h>
#import "VEInstallDataEncryptProvider.h"
#import "VEInstallDataCompressProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallNetwork : NSObject

@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign, getter=isEncryptEnable) BOOL encryptEnable;
@property (nonatomic, copy, nullable) Class<VEInstallDataEncryptProvider> encryptProvider;
@property (nonatomic, copy, nullable) Class<VEInstallDataCompressProvider> compressProvider;

+ (instancetype)network;

- (void)invalidateAndCancel;

- (void)finishAndInvalidate;

- (void)POST:(NSString *)URLString parameters:(nullable NSDictionary *)parameter success:(nullable void(^)(NSInteger statusCode,  id _Nonnull result))success failure:(nullable void (^)(NSError *error))failure;

- (void)POST:(NSString *)URLString parameters:(nullable NSDictionary *)parameter headers:(nullable NSDictionary<NSString *, NSString *> *)headers success:(nullable void(^)(NSInteger statusCode,  id _Nonnull result))success failure:(nullable void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
