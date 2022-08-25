//
//  VEInstallConnection.m
//  VEInstall
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallConnection.h"
#import "VEInstallReachability.h"
#import "VEInstallCellular.h"

@interface VEInstallConnection ()

@property (nonatomic, assign) VEInstallNetworkConnectionType connection;
@property (nonatomic, copy) NSString *connectMethodName;

@end

@implementation VEInstallConnection

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance {
    static VEInstallConnection *sharedInstance = nil;
    static dispatch_once_t onceTVEInstallen;
    dispatch_once(&onceTVEInstallen, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onConnectionChanged)
                                                     name:VEInstallNotificationReachabilityChanged
                                                   object:nil];
        [self onConnectionChanged];
    }

    return self;
}

- (VEInstallNetworkConnectionType)cellularConnection {
    VEInstallCellularServiceType serviceType = [[VEInstallCellular sharedInstance] currentDataServiceType];
    VEInstallCellularConnectionType connectionType = [[VEInstallCellular sharedInstance] cellularConnectionTypeForService:serviceType];
    
    switch (connectionType) {
        case VEInstallCellularConnectionType5G:
            return VEInstallNetworkConnectionType5G;
        case VEInstallCellularConnectionType4G:
            return VEInstallNetworkConnectionType4G;
        case VEInstallCellularConnectionType3G:
            return VEInstallNetworkConnectionType3G;
        case VEInstallCellularConnectionType2G:
            return VEInstallNetworkConnectionType2G;
        case VEInstallCellularConnectionTypeUnknown:
            return VEInstallNetworkConnectionTypeMobile;
        case VEInstallCellularConnectionTypeNone:
            return VEInstallNetworkConnectionTypeNone;
    }
}

- (void)onConnectionChanged {
    VEInstallReachabilityStatus status = [[VEInstallReachability sharedInstance] currentReachabilityStatus];
    
    /* update self.connection */
    switch (status) {
        case VEInstallReachabilityStatusNotReachable:
            self.connection = VEInstallNetworkConnectionTypeNone;
            break;
        case VEInstallReachabilityStatusReachableViaWiFi:
            self.connection = VEInstallNetworkConnectionTypeWiFi;
            break;
        case VEInstallReachabilityStatusReachableViaWWAN:
            self.connection = [self cellularConnection];
            break;

    }

    /* update self.connectMethodName */
    switch (self.connection) {
        case VEInstallNetworkConnectionTypeWiFi:
            self.connectMethodName = @"WIFI";
            break;
        case VEInstallNetworkConnectionType2G:
            self.connectMethodName = @"2G";
            break;
        case VEInstallNetworkConnectionType3G:
            self.connectMethodName = @"3G";
            break;
        case VEInstallNetworkConnectionType4G:
            self.connectMethodName = @"4G";
            break;
        case VEInstallNetworkConnectionType5G:
            self.connectMethodName = @"5G";
            break;
        case VEInstallNetworkConnectionTypeMobile:
            self.connectMethodName = @"mobile";
            break;
        default:
            self.connectMethodName = nil;
            break;
    }
}


@end
