//
//  VEInstallIDFAManager.h
//  VEInstall
//
//  Created by KiBen on 2021/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VEInstallAuthorizationStatus) {
    VEInstallAuthorizationStatusNotDetermined = 0,
    VEInstallAuthorizationStatusRestricted,
    VEInstallAuthorizationStatusDenied,
    VEInstallAuthorizationStatusAuthorized
};

@interface VEInstallIDFAManager : NSObject

+ (NSString *_Nullable)trackingIdentifier;
+ (VEInstallAuthorizationStatus)authorizationStatus;
+ (void)requestTrackingAuthorizationWithCompletionHandler:(void(^)(VEInstallAuthorizationStatus status))completion;

@end

NS_ASSUME_NONNULL_END
