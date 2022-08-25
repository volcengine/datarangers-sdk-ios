//
//  VEInstallNetworkReachability.m
//  VEInstall
//
//  Created by KiBen on 2021/9/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallNetworkReachability.h"
#import "VEInstallReachability+Cellular.h"
#import "VEInstallConnection.h"

@implementation VEInstallNetworkReachability

+ (NSString *)carrierName {
    return [VEInstallReachability carrierName];
}

+ (NSString *)carrierMCC {
    return [VEInstallReachability carrierMCC];
}

+ (NSString *)carrierMNC {
    return [VEInstallReachability carrierMNC];
}

+ (BOOL)isNetworkConnected {
    return [VEInstallReachability isNetworkConnected];
}

+ (VEInstallNetworkType)networkType {
    return [VEInstallConnection sharedInstance].connection;
}

+ (NSString *)networkTypeName {
    return [VEInstallConnection sharedInstance].connectMethodName;
}

+ (void)addNetworkObserver:(id)observer selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:VEInstallNotificationReachabilityChanged object:nil];
}

+ (void)removeNetworkObserver:(id)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:VEInstallNotificationReachabilityChanged object:nil];
}

@end
