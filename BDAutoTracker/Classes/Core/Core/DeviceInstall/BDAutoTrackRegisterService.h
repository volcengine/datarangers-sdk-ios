//
//  BDAutoTrackRegisterService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"
#import "BDAutoTrackNotifications.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackRegisterService : BDAutoTrackService

@property (atomic, copy, readonly) NSString *deviceID;
@property (atomic, copy, readonly) NSString *installID;
@property (atomic, copy) NSString *ssID;  // 数说ID
@property (nonatomic, readonly) BOOL isNewUser;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)reloadParameters;
- (void)addRegisteredParameters:(NSMutableDictionary *)result;

- (void)addRegisterParameters:(NSMutableDictionary *)result;
- (BOOL)updateParametersWithResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse;

- (void)postRegisterSuccessNotificationWithDataSource:(BDAutoTrackNotificationDataSource)dataSource;

- (NSString *)storageKeyWithPrefix:(NSString *)prefix;
@end

FOUNDATION_EXTERN BOOL bd_registerServiceAvailableForAppID(NSString *appID);
FOUNDATION_EXTERN void bd_registeredAddParameters(NSMutableDictionary *result, NSString *appID);
FOUNDATION_EXTERN void bd_registerAddParameters(NSMutableDictionary *result, NSString *appID);
FOUNDATION_EXTERN BOOL bd_registerUpdateParameters(NSDictionary *response, NSString *appID);
FOUNDATION_EXTERN void bd_registerReloadParameters(NSString *appID);

FOUNDATION_EXTERN NSString *_Nullable bd_registerRangersDeviceID(NSString *appID);
FOUNDATION_EXTERN NSString *_Nullable bd_registerinstallID(NSString *appID);
FOUNDATION_EXTERN NSString *_Nullable bd_registerSSID(NSString *appID);

FOUNDATION_EXTERN BDAutoTrackRegisterService * bd_registerServiceForAppID(NSString *appID);

NS_ASSUME_NONNULL_END
