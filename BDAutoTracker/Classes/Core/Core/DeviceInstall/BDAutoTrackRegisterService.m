//
//  BDAutoTrackRegisterService.m
//  RangersAppLog
//
//  Created by bob on 2019/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrack.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackLocalConfigService.h"

#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackDeviceHelper.h"

#import "NSDictionary+VETyped.h"
#import "BDAutoTrack+Private.h"

static NSString *const kAppLogCDKey         = @"kAppLogCDKey";
static NSString *const kAppLogDeviceIDKey   = @"kAppLogBDDidKey";
static NSString *const kAppLogInstallIDKey  = @"kAppLogInstallIDKey";
static NSString *const kAppLogSSIDKey       = @"kAppLogSSIDKey";

static NSString *const kAppLogDeviceID      = @"device_id";

@interface BDAutoTrackRegisterService ()

@property (atomic, copy) NSString *deviceID;
@property (atomic, copy) NSString *installID;
@property (atomic, copy) NSString *cdValue;
@property (nonatomic) BOOL isNewUser;

@property (nonatomic, copy) BDAutoTrackServiceVendor serviceVendor;

@property (nonatomic) NSURLResponse *lastURLResponse;
@end

@implementation BDAutoTrackRegisterService

- (instancetype)initWithAppID:(NSString *)appID  {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameRegister;
        [self reloadParameters];
        if ([self serviceAvailable]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self postRegisterSuccessNotificationWithDataSource:BDAutoTrackNotificationDataSourceLocalCache];
            });
        }
    }

    return self;
}


- (BOOL)serviceAvailable {
    NSString *deviceID = self.deviceID;
    NSString *installID = self.installID;

    return deviceID.length > 0 && installID.length > 0;
}

- (void)addRegisteredParameters:(NSMutableDictionary *)result {
    [result setValue:[self.ssID mutableCopy] forKey:kBDAutoTrackSSID];
    [result setValue:@(BDAutoTrackerSDKVersionCode) forKey:kBDAutoTrackerSDKVersionCode];
    [result setValue:[self.installID mutableCopy] forKey:kBDAutoTrackInstallID];
    if (self.cdValue.length < 1) {
        [result setValue:[self.deviceID mutableCopy] forKey:kAppLogDeviceID];
    } else {
        [result setValue:[self.deviceID mutableCopy] forKey:kBDAutoTrackBDDid];
    }
    
#if TARGET_OS_OSX
    [result setValue:bd_device_uuid() forKey:kBDAutoTrackMacOSUUID];
    [result setValue:bd_device_serial() forKey:kBDAutoTrackMacOSSerial];
#endif
    
    
}

- (void)addRegisterParameters:(NSMutableDictionary *)result {
    [result setValue:[self.cdValue mutableCopy] forKey:kBDAutoTrackCD];
}


- (BOOL)updateParametersWithResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse {
    if (![responseDict isKindOfClass:[NSDictionary class]] || responseDict.count < 1) {
        return NO;
    }

    NSString *remoteInstallID = [responseDict vetyped_stringForKey:kBDAutoTrackInstallID];
    if([remoteInstallID integerValue] <= 0) {
        return NO;
    }
    NSString *remoteDeviceID = [responseDict vetyped_stringForKey:kBDAutoTrackBDDid] ?: [responseDict vetyped_stringForKey:kAppLogDeviceID];
    NSString *remoteCDValue = [responseDict vetyped_stringForKey:kBDAutoTrackCD];
    NSString *remoteSSID = [responseDict vetyped_stringForKey:kBDAutoTrackSSID];
    NSInteger isNewUser = [responseDict vetyped_integerForKey:@"new_user"];
    
    if (remoteInstallID.length > 0
        && remoteDeviceID.length > 0) {
        self.installID = remoteInstallID;
        self.deviceID = remoteDeviceID;
        self.ssID = remoteSSID;
        self.cdValue = remoteCDValue;
        self.isNewUser = isNewUser != 0;
        [self saveAllID];
        
        self.lastURLResponse = [urlResponse copy];
        return YES;
    }

    return NO;
}

- (NSString *)storageKeyWithPrefix:(NSString *)prefix {
    BDAutoTrackServiceVendor vendor = self.serviceVendor;
    NSString *key = prefix;
    
    if (vendor && vendor.length > 0) {
        key = [key stringByAppendingFormat:@"_%@", vendor];
    }

    return key;
}

- (void)reloadParameters {
    self.serviceVendor =  [BDAutoTrack trackWithAppID:self.appID].localConfig.serviceVendor;

    NSString *deviceIDKey = [self storageKeyWithPrefix:kAppLogDeviceIDKey];
    NSString *installIDKey = [self storageKeyWithPrefix:kAppLogInstallIDKey];
    NSString *ssIDKey = [self storageKeyWithPrefix:kAppLogSSIDKey];
    NSString *cdKey = [self storageKeyWithPrefix:kAppLogCDKey];
    
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    self.installID = [defaults stringValueForKey:installIDKey];
    self.ssID = [defaults stringValueForKey:ssIDKey];

    self.deviceID = [defaults stringValueForKey:deviceIDKey];
    self.cdValue = [defaults stringValueForKey:cdKey];
}

- (void)saveAllID {
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    if (tracker.config.newUserMode) {
        return;
    }
    NSString *deviceID = self.deviceID;
    NSString *installID = self.installID;
    NSString *ssID = self.ssID;
    NSString *cdValue = self.cdValue;

    NSString *deviceIDKey = [self storageKeyWithPrefix:kAppLogDeviceIDKey];
    NSString *installIDKey = [self storageKeyWithPrefix:kAppLogInstallIDKey];
    NSString *ssIDKey = [self storageKeyWithPrefix:kAppLogSSIDKey];
    NSString *cdKey = [self storageKeyWithPrefix:kAppLogCDKey];

    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
    [defaults setValue:cdValue forKey:cdKey];
    [defaults setValue:deviceID forKey:deviceIDKey];
    [defaults setValue:installID forKey:installIDKey];
    [defaults setValue:ssID forKey:ssIDKey];
    [defaults saveDataToFile];
}

#pragma mark - postRegisterNotification
- (void)postRegisterSuccessNotificationWithDataSource:(BDAutoTrackNotificationDataSource)dataSource {
    NSString *appID = self.appID;
    NSString *deviceID = self.deviceID;
    NSString *installID = self.installID;
    NSString *ssID = self.ssID;
   
    NSNumber *isNewUser = @(self.isNewUser);
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    NSString *uuid = tracker.localConfig.syncUserUniqueID;

    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:appID forKey:kBDAutoTrackNotificationAppID];
    [userInfo setValue:deviceID forKey:kBDAutoTrackNotificationRangersDeviceID];
    [userInfo setValue:installID forKey:kBDAutoTrackNotificationInstallID];
    [userInfo setValue:ssID forKey:kBDAutoTrackNotificationSSID];
    [userInfo setValue:uuid forKey:kBDAutoTrackNotificationUserUniqueID];
    [userInfo setValue:dataSource forKey:kBDAutoTrackNotificationDataSource];
    [userInfo setValue:isNewUser forKey:kBDAutoTrackNotificationIsNewUser];
    if ([dataSource isEqualToString:BDAutoTrackNotificationDataSourceServer]) {
        [userInfo setValue:self.lastURLResponse.URL.absoluteString forKey:kBDAutoTrackNotificationDataSourceURL];
    }
    
    if ([dataSource isEqualToString:BDAutoTrackNotificationDataSourceServer]) {
        NSString *currentType = tracker.localConfig.syncUserUniqueIDType;
        [tracker.localConfig updateUser:uuid type:currentType ssid:ssID];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterSuccess
                                                        object:nil
                                                      userInfo:userInfo];
}

@end

BDAutoTrackRegisterService * bd_registerServiceForAppID(NSString *appID) {
    return (BDAutoTrackRegisterService *)bd_standardServices(BDAutoTrackServiceNameRegister, appID);
}

BOOL bd_registerServiceAvailableForAppID(NSString *appID) {
    return [bd_registerServiceForAppID(appID) serviceAvailable];
}

void bd_registeredAddParameters(NSMutableDictionary *result, NSString *appID) {
    [bd_registerServiceForAppID(appID) addRegisteredParameters:result];
}

void bd_registerAddParameters(NSMutableDictionary *result, NSString *appID) {
    [bd_registerServiceForAppID(appID) addRegisterParameters:result];
}

void bd_registerReloadParameters(NSString *appID) {
    [bd_registerServiceForAppID(appID) reloadParameters];
}

NSString *bd_registerRangersDeviceID(NSString *appID) {
    return bd_registerServiceForAppID(appID).deviceID;
}

NSString *bd_registerinstallID(NSString *appID) {
    return bd_registerServiceForAppID(appID).installID;
}

NSString *bd_registerSSID(NSString *appID) {
    return bd_registerServiceForAppID(appID).ssID;
}
