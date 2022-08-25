//
//  VEInstallConfig.m
//  VEInstall
//
//  Created by KiBen on 2021/9/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallConfig.h"

@implementation VEInstallConfig

- (instancetype)init {
    if (self = [super init]) {
        _retryTimes = 3;
        _retryDuration = 5;
        _timeoutInterval = 15;
        _encryptEnable = YES;
    }
    return self;
}

//- (id)copyWithZone:(NSZone *)zone {
//
//    VEInstallConfig *config = [VEInstallConfig new];
//    config.appID = [self.appID copy];
//    config.channel = [self.channel copy];
//    config.name = [self.name copy];
//    config.userUniqueID = [self.userUniqueID copy];
//    config.retryTimes = self.retryTimes;
//    config.retryDuration = self.retryDuration;
//    return config;
//}

@end
