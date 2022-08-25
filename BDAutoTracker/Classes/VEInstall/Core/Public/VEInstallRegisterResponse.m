//
//  VEInstallRegisterValue.m
//  VEInstall
//
//  Created by KiBen on 2021/9/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallRegisterResponse+Private.h"

@implementation VEInstallRegisterResponse

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    
    if (self = [super init]) {
        _dict = [dict copy];
        _deviceID = [dict objectForKey:@"bd_did"] ?: kVEInstallRegisterIDZero;
        _installID = [dict objectForKey:@"install_id_str"] ?: kVEInstallRegisterIDZero;
        _ssID = [dict objectForKey:@"ssid"] ?: kVEInstallRegisterIDZero;
        _cdValue = [dict objectForKey:@"cd"] ?: kVEInstallRegisterIDZero;
        _isNewUser = [[dict objectForKey:@"new_user"] boolValue];
        _deviceToken = [dict objectForKey:@"device_token"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {

    VEInstallRegisterResponse *response = [VEInstallRegisterResponse new];
    response.deviceID = self.deviceID;
    response.installID = self.installID;
    response.cdValue = self.cdValue;
    response.ssID = self.ssID;
    response.deviceToken = self.deviceToken;
    response.fromCache = self.fromCache;
    response.isNewUser = self.isNewUser;
    response.dict = self.dict;
    response.userUniqueID = self.userUniqueID;
    return response;
}

- (BOOL)isValid {
    return !([self.deviceID isEqualToString:kVEInstallRegisterIDZero] ||
                [self.installID isEqualToString:kVEInstallRegisterIDZero] ||
                [self.cdValue isEqualToString:kVEInstallRegisterIDZero] ||
                [self.ssID isEqualToString:kVEInstallRegisterIDZero]);
}

- (NSString *)description {
    return @{
        @"deviceID" : self.deviceID ?: @"",
        @"installID" : self.installID ?: @"",
        @"ssID" : self.ssID ?: @"",
        @"cdValue" : self.cdValue ?: @"",
        @"deviceToken" : self.deviceToken ?: @"",
        @"isNewUser" : @(self.isNewUser),
        @"userUniqueID" : self.userUniqueID ?: @""
    }.description;
}
@end
