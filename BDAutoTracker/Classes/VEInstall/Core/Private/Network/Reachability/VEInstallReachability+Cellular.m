//
//  VEInstallReachability+Cellular.m
//  VEInstall
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallReachability+Cellular.h"
#import <CoreTelephony/CTCarrier.h>

@implementation VEInstallReachability (Cellular)

+ (BOOL)isNetworkConnected {
    VEInstallReachabilityStatus status = [[VEInstallReachability sharedInstance] currentReachabilityStatus];
    return status == VEInstallReachabilityStatusReachableViaWiFi || status == VEInstallReachabilityStatusReachableViaWWAN;
}

+ (VEInstallCellularConnectionType)cellularConnectionType {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    
    return [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
}

+ (BOOL)is2GConnected {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    return [self is2GConnectedForService:service];
}

+ (BOOL)is3GConnected {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    
    return [self is3GConnectedForService:service];
}

+ (BOOL)is4GConnected {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    
    return [self is4GConnectedForService:service];
}

+ (BOOL)is5GConnected {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    return [self is5GConnectedForService:service];
}

+ (NSString *)carrierName {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];

    return [self carrierNameForService:service];
}

+ (NSString *)carrierMCC {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];

    return [self carrierMCCForService:service];
}

+ (NSString *)carrierMNC {
    VEInstallCellularServiceType service = [[VEInstallCellular sharedInstance] currentDataServiceType];
    
    return [self carrierMNCForService:service];
}

+ (VEInstallCellularConnectionType)cellularConnectionTypeForService:(VEInstallCellularServiceType)service {
    
    return [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
}

+ (BOOL)is2GConnectedForService:(VEInstallCellularServiceType)service {
    VEInstallCellularConnectionType connectionType = [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
    return  connectionType == VEInstallCellularConnectionType2G;;
}

+ (BOOL)is3GConnectedForService:(VEInstallCellularServiceType)service {
    VEInstallCellularConnectionType connectionType = [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == VEInstallCellularConnectionType3G;
}

+ (BOOL)is4GConnectedForService:(VEInstallCellularServiceType)service {
    VEInstallCellularConnectionType connectionType = [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == VEInstallCellularConnectionType4G;
}

+ (BOOL)is5GConnectedForService:(VEInstallCellularServiceType)service {
    VEInstallCellularConnectionType connectionType = [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:service];
    
    return connectionType == VEInstallCellularConnectionType5G;
}

+ (NSString *)carrierNameForService:(VEInstallCellularServiceType)service {
    CTCarrier *carrier =[[VEInstallCellular sharedInstance] carrierForService:service];

    return carrier.carrierName;
}

+ (NSString *)carrierMCCForService:(VEInstallCellularServiceType)service {
    CTCarrier *carrier =[[VEInstallCellular sharedInstance] carrierForService:service];

    return carrier.mobileCountryCode;
}

+ (NSString *)carrierMNCForService:(VEInstallCellularServiceType)service {
    CTCarrier *carrier =[[VEInstallCellular sharedInstance] carrierForService:service];

    return carrier.mobileNetworkCode;
}
@end
