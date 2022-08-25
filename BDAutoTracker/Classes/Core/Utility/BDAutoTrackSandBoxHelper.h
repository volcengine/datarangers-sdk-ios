//
//  TTInstallSandBoxHelper.h
//  Pods
//
//  Created by 冯靖君 on 17/2/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * bd_sandbox_appName(void);
FOUNDATION_EXTERN NSString * bd_sandbox_appDisplayName(void);
FOUNDATION_EXTERN NSString * bd_sandbox_releaseVersion(void);
FOUNDATION_EXTERN NSString * bd_sandbox_buildVersion(void);
FOUNDATION_EXTERN NSString * bd_sandbox_bundleIdentifier(void);
FOUNDATION_EXTERN NSString * bd_sandbox_userAgent(void);
FOUNDATION_EXTERN BOOL bd_sandbox_isUpgradeUser(void);

NS_ASSUME_NONNULL_END
