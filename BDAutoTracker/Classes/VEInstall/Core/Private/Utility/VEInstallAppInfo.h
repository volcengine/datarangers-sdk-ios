//
//  VEInstallAppInfo.h
//  VEInstall
//
//  Created by KiBen on 2021/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEInstallAppInfo : NSObject

+ (NSString *)releaseVersion;
+ (NSString *)buildVersion;
+ (NSString *)displayName;

@end

NS_ASSUME_NONNULL_END
