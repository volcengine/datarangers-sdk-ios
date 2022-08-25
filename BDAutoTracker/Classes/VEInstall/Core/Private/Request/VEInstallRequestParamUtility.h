//
//  VEInstallRequestParamUtility.h
//  VEInstall
//
//  Created by KiBen on 2019/9/27.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VEInstall;
@interface VEInstallRequestParamUtility : NSObject

+ (NSDictionary *)registerDeviceParametersForCurrentInstall:(VEInstall *)install;

+ (NSString *)sortedQueryEncodedStringWithParameter:(NSDictionary *)parameter;

+ (NSString *)MD5AuthWithRequestParameter:(NSDictionary *)paramDict timestamp:(unsigned long long)timestamp;
@end

NS_ASSUME_NONNULL_END
