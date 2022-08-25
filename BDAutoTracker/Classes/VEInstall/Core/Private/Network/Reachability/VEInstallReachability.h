//
//  VEInstallReachability.h
//  Masonry
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int32_t, VEInstallReachabilityStatus) {
    VEInstallReachabilityStatusNotReachable    = 0,
    VEInstallReachabilityStatusReachableViaWiFi,
    VEInstallReachabilityStatusReachableViaWWAN
};

FOUNDATION_EXTERN NSString *VEInstallNotificationReachabilityChanged;
 
@interface VEInstallReachability : NSObject

@property (nonatomic, assign, readonly) BOOL telephoneInfoIndeterminateStatus;

+ (instancetype)sharedInstance;

- (void)startNotifier;

- (VEInstallReachabilityStatus)currentReachabilityStatus;

@end

NS_ASSUME_NONNULL_END
