//
//  BDAutoTrackIdentifier.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/6/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackConfig;
@interface BDAutoTrackIdentifier : NSObject

- (instancetype)initWithConfig:(BDAutoTrackConfig *)tracker;

@property (nonatomic, copy, nullable) NSString *deviceID;

@property (nonatomic, copy, nullable) NSString *installID;

@property (nonatomic, copy, nullable) NSString *ssID;

@property (nonatomic, copy, nullable) NSString *userUniqueID;

@property (nonatomic, copy, nullable) NSString *userUniqueIDType;

@property (readonly) NSString *identifierForTracking API_UNAVAILABLE(macos);

@property (readonly) NSString *identifierForVendor API_UNAVAILABLE(macos);;

@property (nonatomic, assign) BOOL isNewUser;

- (BOOL)deviceAvalible;

- (void)requestDeviceRegistration;

- (void)flush;

#pragma mark - common Parameters

- (void)solveInstallParameters:(NSMutableDictionary *)input;

- (void)solveUserParameters:(NSMutableDictionary *)input;


- (NSString *)synchronousfetchSSID:(NSString *)udid;


@end

NS_ASSUME_NONNULL_END
