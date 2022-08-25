//
//  VEInstallRequestProxy.h
//  VEInstall
//
//  Created by KiBen on 2021/9/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "VEInstallRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallRequestProxy : NSObject <VEInstallRequestProtocol>

@property (nonatomic, assign) NSUInteger retryTimes;

@property (nonatomic, assign) NSTimeInterval retryDuration;

@end

NS_ASSUME_NONNULL_END
