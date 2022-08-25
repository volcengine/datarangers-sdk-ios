//
//  VEInstallManager.m
//  VEInstall
//
//  Created by KiBen on 2021/9/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallManager.h"
#import <pthread/pthread.h>

@implementation VEInstallConfig (Singleton)

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    static VEInstallConfig *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [VEInstallConfig new];
    });
    return _instance;
}

@end


@implementation VEInstallManager {
    pthread_mutex_t _mutex;
    NSMutableDictionary<NSString *, VEInstall *> *_installCaches;
}

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    static VEInstallManager *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [VEInstallManager new];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _installCaches = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_mutex, NULL);
    }
    return self;
}

- (VEInstall *)installForAppID:(NSString *)appID {
    
    VEInstall *install = nil;
    pthread_mutex_lock(&_mutex);
    install = _installCaches[appID];
    pthread_mutex_unlock(&_mutex);
    
    return install;
}

- (void)setInstall:(VEInstall *)install forAppID:(NSString *)appID {
    
    pthread_mutex_lock(&_mutex);
    _installCaches[appID] = install;
    pthread_mutex_unlock(&_mutex);
}

+ (VEInstall *)defaultInstall {
    
    static dispatch_once_t onceToken;
    static VEInstall *_install = nil;
    dispatch_once(&onceToken, ^{
        _install = [[VEInstall alloc] initWithConfig:[VEInstallConfig sharedInstance]];
        [[VEInstallManager sharedInstance] setInstall:_install forAppID:[VEInstallConfig sharedInstance].appID];
    });
    
    return _install;
}

+ (VEInstall *)installForAppID:(NSString *)appID {
    return [[VEInstallManager sharedInstance] installForAppID:appID];
}

+ (VEInstall *)createInstallWithConfig:(VEInstallConfig *)config {
    
    VEInstall *install = [[VEInstall alloc] initWithConfig:config];
    [[VEInstallManager sharedInstance] setInstall:install forAppID:config.appID];
    return install;
}
@end
