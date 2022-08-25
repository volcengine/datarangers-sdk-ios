//
//  VEInstallRequestProxy.m
//  VEInstall
//
//  Created by KiBen on 2021/9/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallRequestProxy.h"
#import "VEInstallRequest.h"

@implementation VEInstallRequestProxy {
    VEInstallRequest *_request;
}

@synthesize encryptEnable = _encryptEnable;
@synthesize encryptProvider = _encryptProvider;
@synthesize timeoutInterval = _timeoutInterval;

- (instancetype)init {
    
    if (self = [super init]) {
        _request = [VEInstallRequest new];
        _retryTimes = 3;
        _retryDuration = 5;
    }
    return self;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    _request.timeoutInterval = timeoutInterval;
}

- (void)setEncryptEnable:(BOOL)encryptEnable {
    _encryptEnable = encryptEnable;
    _request.encryptEnable = encryptEnable;
}

- (void)setEncryptProvider:(Class<VEInstallDataEncryptProvider>)encryptProvider {
    if (encryptProvider) {
        _encryptProvider = [(Class)encryptProvider copy];
        _request.encryptProvider = encryptProvider;
    }
}

- (void)jsonRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    
    [self _jsonRequestWithURLString:URLString parameters:parameter retryTimes:self.retryTimes retryDuration:self.retryDuration success:success failure:failure];
}

- (void)_jsonRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter retryTimes:(NSUInteger)retryTimes retryDuration:(NSTimeInterval)retryDuration success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    
    [_request jsonRequestWithURLString:URLString parameters:parameter success:success failure:^(NSError * _Nonnull error) {
        if (retryTimes > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self _jsonRequestWithURLString:URLString parameters:parameter retryTimes:retryTimes - 1 retryDuration:retryDuration success:success failure:failure];
            });
            return;
        }
        failure(error);
    }];
}

- (void)queryEncodeRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure  {
    
    [self _queryEncodeRequestWithURLString:URLString parameters:parameter retryTimes:self.retryTimes retryDuration:self.retryDuration success:success failure:failure];
}

- (void)_queryEncodeRequestWithURLString:(NSString *)URLString parameters:(NSDictionary *)parameter retryTimes:(NSUInteger)retryTimes retryDuration:(NSTimeInterval)retryDuration success:(void (^)(NSDictionary * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    
    [_request queryEncodeRequestWithURLString:URLString parameters:parameter success:success failure:^(NSError * _Nonnull error) {
        if (retryTimes > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self _queryEncodeRequestWithURLString:URLString parameters:parameter retryTimes:retryTimes - 1 retryDuration:retryDuration success:success failure:failure];
            });
            return;
        }
        failure(error);
    }];
}
@end
