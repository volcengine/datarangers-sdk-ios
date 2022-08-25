//
//  VEInstallRequest.m
//  VEInstall
//
//  Created by KiBen on 2021/9/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallRequest.h"
#import "VEInstallNetwork.h"
#import "VEInstallDefaultCompressProvider.h"
#import "VEInstallErrorInfo.h"

@implementation VEInstallRequest {
    VEInstallNetwork *_network;
}

@synthesize timeoutInterval = _timeoutInterval;
@synthesize encryptEnable = _encryptEnable;
@synthesize encryptProvider = _encryptProvider;

- (instancetype)init {
    if (self = [super init]) {
        _network = [VEInstallNetwork network];
        _network.compressProvider = [VEInstallDefaultCompressProvider class];
    }
    return self;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    _network.timeoutInterval = timeoutInterval;
}

- (void)setEncryptEnable:(BOOL)encryptEnable {
    _encryptEnable = encryptEnable;
    _network.encryptEnable = encryptEnable;
}

- (void)setEncryptProvider:(Class<VEInstallDataEncryptProvider>)encryptProvider {
    if (encryptProvider) {
        _encryptProvider = [(Class)encryptProvider copy];
        _network.encryptProvider = encryptProvider;
    }
}

- (void)jsonRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    [self requestWithURLString:URLString parameters:parameter headers:@{@"Content-Type" : @"application/json"} success:success failure:failure];
}

- (void)queryEncodeRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    [self requestWithURLString:URLString parameters:parameter headers:@{@"Content-Type" : @"application/x-www-form-urlencoded"} success:success failure:failure];
}

- (void)requestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter headers:(NSDictionary *)headers success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    
    [_network POST:URLString parameters:parameter headers:headers success:^(NSInteger statusCode, id  _Nonnull result) {
        if (statusCode != 200 || ![result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *info = VEInstall_error_info(statusCode, @"install request error", result);
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:info];
            failure(error);
            return;
        }
        success(result);
    } failure:failure];
    
}

@end
