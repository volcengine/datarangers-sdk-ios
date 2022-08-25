//
//  VEInstall.m
//  VEInstall
//
//  Created by KiBen on 2021/9/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstall.h"
#import <pthread/pthread.h>
#import "VEInstallNetworkReachability.h"
#import "VEInstallRequestParamUtility.h"
#import "VEInstallRequestProxy.h"
#import "VEInstallLog.h"
#import "VEInstallFileStorage.h"
#import "VEInstallAppInfo.h"
#import "VEInstallLog.h"
#import "VEInstallErrorInfo.h"
#import "VEInstallRegisterResponse+Private.h"
#import "VEInstallRequestProtocol.h"

static NSString *VEInstall_register_file_name(NSString *appID) {
    return [NSString stringWithFormat:@"VEInstall_reg_%@", appID];
}

static void VEInstall_async_main_safe(void(^block)(void)) {
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
        block();
    }else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface VEInstall ()
@property (nonatomic, strong) NSHashTable *observerHashTable;
@property (nonatomic, strong) VEInstallRegisterResponse *registerResponse;
@property (nonatomic, strong) id<VEInstallRequestProtocol> request;
@property (nonatomic, strong) dispatch_queue_t registerRWQueue;

- (instancetype)init;
@end

@implementation VEInstall {
    pthread_mutex_t _observerMutex;
}

- (instancetype)initWithConfig:(VEInstallConfig *)config {
    
    NSParameterAssert(config.appID.length);
    NSParameterAssert(config.channel.length);
    NSParameterAssert(config.name.length);
    NSParameterAssert(config.URLService);
    
    if (self = [self init]) {
        _installConfig = config;
        _registerResponse = [self _responseForAppID:config.appID];
        [VEInstallNetworkReachability addNetworkObserver:self selector:@selector(_networkConnectionChanged)];
        VEInstall_async_main_safe(^{
            // 兼容RangersAppLog原先逻辑
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        });
    }
    return self;
}

- (instancetype)init {
    
    if (self = [super init]) {
        _observerHashTable = [NSHashTable weakObjectsHashTable];
        _registerRWQueue = dispatch_queue_create("VEInstall.register.storage.rw.queue", DISPATCH_QUEUE_CONCURRENT);
        pthread_mutex_init(&_observerMutex, NULL);
    }
    return self;
}

#pragma mark - getter

- (id<VEInstallRequestProtocol>)request {
    if (!_request) {
        VEInstallRequestProxy *request = [VEInstallRequestProxy new];
        _request = request;
    }
    // 配置可能会动态修改，需要保持最新配置
    _request.timeoutInterval = self.installConfig.timeoutInterval;
    ((VEInstallRequestProxy *)_request).retryTimes = self.installConfig.retryTimes;
    ((VEInstallRequestProxy *)_request).retryDuration = self.installConfig.retryDuration;
    _request.encryptEnable = self.installConfig.isEncryptEnable;
    _request.encryptProvider = self.installConfig.encryptProvider;
    return _request;
}

- (NSString *)deviceID {
    
    __block NSString *deviceID = nil;
    dispatch_sync(self.registerRWQueue, ^{
        deviceID = [self.registerResponse.deviceID copy];
    });
    
    return deviceID;
}

- (NSString *)installID {
    
    __block NSString *installID = nil;
    dispatch_sync(self.registerRWQueue, ^{
        installID = [self.registerResponse.installID copy];
    });
    
    return installID;
}

- (NSString *)ssID {
    
    __block NSString *ssID = nil;
    dispatch_sync(self.registerRWQueue, ^{
        ssID = [self.registerResponse.ssID copy];
    });
    
    return ssID;
}

- (NSString *)cdValue {
    
    __block NSString *cdValue = nil;
    dispatch_sync(self.registerRWQueue, ^{
        cdValue = [self.registerResponse.cdValue copy];
    });
    
    return cdValue;
}

- (NSString *)deviceToken {
    
    __block NSString *deviceToken = nil;
    dispatch_sync(self.registerRWQueue, ^{
        deviceToken = [self.registerResponse.deviceToken copy];
    });
    
    return deviceToken;
}

- (BOOL)isNewUser {
    
    __block BOOL isNewUser = nil;
    dispatch_sync(self.registerRWQueue, ^{
        isNewUser = self.registerResponse.isNewUser;
    });
    
    return isNewUser;
}

#pragma mark - public method

- (void)addObserver:(id<VEInstallObserverProtocol>)observer {
    
    if (!observer || ![observer conformsToProtocol:@protocol(VEInstallObserverProtocol)]) return;
    
    __block VEInstallRegisterResponse *response = nil;
    dispatch_sync(self.registerRWQueue, ^{
        response = self.registerResponse;
    });
    if (response && [observer respondsToSelector:@selector(install:didRegisterDeviceWithResponse:)]) {
        VEInstall_async_main_safe(^{
            [observer install:self didRegisterDeviceWithResponse:response];
        });
    }
    
    pthread_mutex_lock(&_observerMutex);
    [self.observerHashTable addObject:observer];
    pthread_mutex_unlock(&_observerMutex);
}

- (void)removeObserver:(id<VEInstallObserverProtocol>)observer {
    
    if (!observer || ![observer conformsToProtocol:@protocol(VEInstallObserverProtocol)]) return;
    
    pthread_mutex_lock(&_observerMutex);
    [self.observerHashTable removeObject:observer];
    pthread_mutex_unlock(&_observerMutex);
}

- (void)registerDevice {
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *parameter = [VEInstallRequestParamUtility registerDeviceParametersForCurrentInstall:self];
    NSString *userUniqueID = [self.installConfig.userUniqueID copy];
    [self.request jsonRequestWithURLString:[self.installConfig.URLService registerDeviceURLStringForAppID:self.installConfig.appID] parameters:parameter success:^(NSDictionary * _Nonnull result) {
        VEInstallRegisterResponse *response = [[VEInstallRegisterResponse alloc] initWithDictionary:result];
        response.userUniqueID = userUniqueID;
        if (![response isValid]) {
            NSDictionary *info = VEInstall_error_info(NSURLErrorBadServerResponse, @"One or more significant id from server is unvalid.", result);
            NSError *error = [NSError errorWithDomain:@"VEInstallBadServerResponse" code:NSURLErrorBadServerResponse userInfo:info];
            [weakSelf _notifyObserversWithRegisterResponse:nil error:error];
            return;
        }
        [weakSelf _saveResponse:response];
        [weakSelf _notifyObserversWithRegisterResponse:response error:nil];
        [weakSelf _postNotificationWithRegisterResponse:response isLocalCache:NO];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf _notifyObserversWithRegisterResponse:nil error:error];
    }];
    
}

- (BOOL)isDeviceRegisted {
    
    __block BOOL isRegisted = NO;
    dispatch_sync(self.registerRWQueue, ^{
        isRegisted = (self.registerResponse.deviceID.length > 0) &&
                            (self.registerResponse.installID.length > 0) &&
                            (self.registerResponse.cdValue.length > 0) &&
                            (self.registerResponse.ssID.length > 0);
    });
    return isRegisted;
}

- (BOOL)clearAllStorageIDs {
    
    __block BOOL result = YES;
    dispatch_sync(self.registerRWQueue, ^{
        result = ve_install_file_delete(VEInstall_register_file_name(self.installConfig.appID));
        InstallLog(@"清除文件缓存的id %@", result ? @"成功" : @"失败");
        // 清理cookie
        NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
        for (NSHTTPCookie *cookie in cookies) {
            if (![cookie.name isEqualToString:@"install_id"]) continue;
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            break;
        }
        
        self.registerResponse = nil;
    });
    return result;
}

#pragma mark - private method

- (void)_saveResponse:(VEInstallRegisterResponse *)response {
    
    dispatch_barrier_async(self.registerRWQueue, ^{
        VEInstallRegisterResponse *copyResponse = [response copy];
        copyResponse.fromCache = YES;
        self.registerResponse = copyResponse;
        
        [self _saveResponseContent:response.dict forAppID:self.installConfig.appID];
    });
    
}

- (void)_saveResponseContent:(NSDictionary *)content forAppID:(NSString *)appID {
    // 注：这里文件存储的是整个json内容
    BOOL result = ve_install_file_save(VEInstall_register_file_name(appID), content);
    InstallLog(@"设备注册内容写入文件%@", result ? @"成功" : @"失败");
}

- (VEInstallRegisterResponse *)_responseForAppID:(NSString *)appID {
    
    __block NSDictionary *content = nil;
    dispatch_sync(self.registerRWQueue, ^{
        content = ve_install_file_load(VEInstall_register_file_name(appID));
        InstallLog(@"从文件读取%@缓存设备注册内容", content ? @"到" : @"不到");
    });
    if (!content) {
        InstallLog(@"从文件读取不到缓存设备注册内容");
        return nil;
    }
    VEInstallRegisterResponse *response = [[VEInstallRegisterResponse alloc] initWithDictionary:content];
    response.fromCache = YES;
    return response;
}

- (void)_notifyObserversWithRegisterResponse:(VEInstallRegisterResponse *_Nullable)response error:(NSError *_Nullable)error {
    
    NSArray<id<VEInstallObserverProtocol>> *observers = nil;
    pthread_mutex_lock(&_observerMutex);
    observers = self.observerHashTable.allObjects;
    pthread_mutex_unlock(&_observerMutex);
    
    for (id<VEInstallObserverProtocol> observer in observers) {
        
        if (error) {
            if ([observer respondsToSelector:@selector(install:didRegisterDeviceFailWithError:)]) {
                [observer install:self didRegisterDeviceFailWithError:error];
            }
        }else {
            if ([observer respondsToSelector:@selector(install:didRegisterDeviceWithResponse:)]) {
                [observer install:self didRegisterDeviceWithResponse:response];
            }
        }
    }
    
}

- (void)_postNotificationWithRegisterResponse:(VEInstallRegisterResponse *)response isLocalCache:(BOOL)isLocalCache {
    if (!isLocalCache) {
        VEInstall_async_main_safe(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VEInstallDidRegisterDeviceNotification object:nil userInfo:@{
                VEInstallNotificationKeyAppID : self.installConfig.appID,
                VEInstallNotificationKeyRegisterResponse : response
            }];
        });
    }
}

#pragma mark - Network Connection Notification
- (void)_networkConnectionChanged {
    
    if ([self isDeviceRegisted]) {
        [VEInstallNetworkReachability removeNetworkObserver:self];
        return;
    }
    VEInstall_async_main_safe(^{
        [self registerDevice];
    });
}

- (void)_applicationWillEnterForeground {

}

@end
