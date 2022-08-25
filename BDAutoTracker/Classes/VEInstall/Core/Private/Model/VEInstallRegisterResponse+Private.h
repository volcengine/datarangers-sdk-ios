//
//  VEInstallRegisterResponse+Private.h
//  Pods
//
//  Created by KiBen on 2021/9/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef VEInstallRegisterResponse_Private_h
#define VEInstallRegisterResponse_Private_h

static NSString *const kVEInstallRegisterIDZero = @"0";

#import "VEInstallRegisterResponse.h"

@interface VEInstallRegisterResponse ()

@property (nonatomic, copy) NSString *deviceID;

@property (nonatomic, copy) NSString *installID;

@property (nonatomic, copy) NSString *cdValue;

@property (nonatomic, copy) NSString *ssID;

@property (nonatomic, assign) BOOL isNewUser;

@property (nonatomic, copy) NSString *deviceToken;

@property (nonatomic, assign) BOOL fromCache;

@property (nonatomic, copy, nullable) NSString *userUniqueID;

@property (nonatomic, copy) NSDictionary *dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (BOOL)isValid;

@end

#endif /* VEInstallRegisterResponse_Private_h */
