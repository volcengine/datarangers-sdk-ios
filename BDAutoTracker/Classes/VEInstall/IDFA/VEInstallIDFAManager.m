//
//  VEInstallIDFAManager.h
//  VEInstall
//
//  Created by KiBen on 2021/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallIDFAManager.h"
#import <AdSupport/ASIdentifierManager.h>
#import "VEInstallIDFA.h"

#ifdef __IPHONE_14_0
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

@implementation VEInstallIDFAManager

+ (NSString *)trackingIdentifier {
    return [VEInstallIDFA idfa];
}

+ (VEInstallAuthorizationStatus)authorizationStatus {
    
#ifdef __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        return (VEInstallAuthorizationStatus)[ATTrackingManager trackingAuthorizationStatus];
    }
#endif
    
    if ([ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled) {
        return VEInstallAuthorizationStatusAuthorized;
    }
    return VEInstallAuthorizationStatusDenied;
}

+ (void)requestTrackingAuthorizationWithCompletionHandler:(void(^)(VEInstallAuthorizationStatus status))completion {
    
#ifdef __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            if (completion) {
                completion((VEInstallAuthorizationStatus)status);
            }
        }];
        return;
    }
#endif
    
    if (completion) {
        completion([VEInstallIDFAManager authorizationStatus]);
    }
}

@end
