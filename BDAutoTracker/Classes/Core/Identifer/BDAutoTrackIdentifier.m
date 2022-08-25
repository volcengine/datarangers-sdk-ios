//
//  BDAutoTrackIdentifier.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/6/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackIdentifier.h"
#import "VEInstall.h"
#import "VEInstallConfig.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackNotifications.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackDefaults.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackURLHostProvider.h"
#import "VEInstallDeviceInfo.h"
#import "VEInstallRequestProxy.h"
#import "VEInstallRequestParamUtility.h"
#import "VEInstallRegisterResponse+Private.h"

@interface  BDAutoTrackInstallProvider : NSObject<VEInstallDataEncryptProvider,VEInstallURLService>
@end

@implementation BDAutoTrackInstallProvider

+ (NSData *_Nullable)encryptData:(NSData *)originalData forAppID:(NSString *)appID
{
    
    return nil;
}

+ (NSString *)registerDeviceURLStringForAppID:(NSString *)appID
{
    NSString *url = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLRegister appID:appID];
    return url;
}

@end



@interface BDAutoTrackIdentifier()<VEInstallObserverProtocol>

@end

@implementation BDAutoTrackIdentifier {
    NSString *appId;
    VEInstall *install;
    VEInstallRequestProxy *request;
    BDAutoTrackDefaults *storage;
    
}

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config;
{
    NSString *appId = config.appID;
    if (!config
        || appId.length <= 0) {
        return nil;
    }
    if (self = [super init]) {
        self->appId = [appId copy];
        storage = [BDAutoTrackDefaults defaultsWithAppID:self->appId];
        self.userUniqueID = [storage stringValueForKey:kBDAutoTrackConfigUserUniqueID];
        self.userUniqueIDType = [storage stringValueForKey:kBDAutoTrackConfigUserUniqueIDType];

        VEInstallConfig *installConfig = [VEInstallConfig new];
        installConfig.appID = self->appId;
        installConfig.channel = config.channel;
        installConfig.name = config.appName;
        installConfig.encryptEnable = config.logNeedEncrypt;
        installConfig.encryptProvider = [BDAutoTrackInstallProvider class];
        installConfig.URLService = [BDAutoTrackInstallProvider class];

        install = [[VEInstall alloc] initWithConfig:installConfig];
        [install addObserver:self];
        self.ssID = install.ssID;
        self.deviceID = install.deviceID;
        self.installID = install.installID;
        [self postNotification:BDAutoTrackNotificationDataSourceLocalCache];
        
        request = [VEInstallRequestProxy new];
        request.timeoutInterval = 5.0f;
        request.encryptEnable = installConfig.encryptEnable;
        request.encryptProvider = installConfig.encryptProvider;
    }
    return self;
}

- (void)requestDeviceRegistration;
{
    install.installConfig.userUniqueID = self.userUniqueID;
    [install registerDevice];
}

- (BOOL)deviceAvalible
{
    return (self.deviceID.length > 0
            && self.installID.length > 0);
}

- (void)flush
{
    [storage setValue:self.userUniqueID forKey:kBDAutoTrackConfigUserUniqueID];
    [storage setValue:self.userUniqueIDType forKey:kBDAutoTrackConfigUserUniqueIDType];
    [storage saveDataToFile];
}

- (void)solveInstallParameters:(NSMutableDictionary *)input
{
    [input setValue:self.ssID forKey:kBDAutoTrackSSID];
    [input setValue:@(BDAutoTrackerSDKVersionCode) forKey:kBDAutoTrackerSDKVersionCode];
    [input setValue:self.installID forKey:kBDAutoTrackInstallID];
    if (install.cdValue.length < 1) {
        [input setValue:self.deviceID forKey:kBDAutoTrackDeviceID];
    } else {
        [input setValue:self.deviceID forKey:kBDAutoTrackBDDeviceID];
    }
}

- (void)solveUserParameters:(NSMutableDictionary *)input
{
    [input setValue:self.userUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
    [input setValue:self.userUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
}

- (NSString *)synchronousfetchSSID:(NSString *)udid
{
    NSMutableDictionary *paramters = [NSMutableDictionary dictionaryWithDictionary:[VEInstallRequestParamUtility registerDeviceParametersForCurrentInstall:install]];
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithDictionary:[paramters objectForKey:@"header"] ?:@{}];
    [header removeObjectForKey:@"ssid"];
    [header setValue:udid?:[NSNull null] forKey:@"user_unique_id"];
    [paramters setValue:header forKey:@"header"];
    
    __block NSString *ssID = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [request jsonRequestWithURLString:[install.installConfig.URLService registerDeviceURLStringForAppID:install.installConfig.appID] parameters:paramters success:^(NSDictionary * _Nonnull result) {
        VEInstallRegisterResponse *response = [[VEInstallRegisterResponse alloc] initWithDictionary:result];
        if ([response isValid]) {
            ssID = response.ssID;
        }
        dispatch_semaphore_signal(semaphore);
    } failure:^(NSError * _Nonnull error) {
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (request.timeoutInterval + 1) * NSEC_PER_SEC));
    return ssID;
    
}

#pragma mark - post BDAutoTrackNotificationRegisterSuccess

- (void)postNotification:(BDAutoTrackNotificationDataSource)dataSource
{
    if (self.deviceAvalible) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setValue:appId forKey:kBDAutoTrackNotificationAppID];
        [userInfo setValue:self.deviceID forKey:kBDAutoTrackNotificationRangersDeviceID];
        [userInfo setValue:self.installID forKey:kBDAutoTrackNotificationInstallID];
        [userInfo setValue:self.ssID forKey:kBDAutoTrackNotificationSSID];
        [userInfo setValue:self.userUniqueID forKey:kBDAutoTrackNotificationUserUniqueID];
        [userInfo setValue:dataSource forKey:kBDAutoTrackNotificationDataSource];
        [userInfo setValue:@(install.isNewUser) forKey:kBDAutoTrackNotificationIsNewUser];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterSuccess
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
}


#pragma mark - install observer

- (void)install:(VEInstall *)install didRegisterDeviceWithResponse:(VEInstallRegisterResponse *)registerReponse
{
    if ( [(registerReponse.userUniqueID?:@"") isEqualToString:(self.userUniqueID?:@"")]) {
        self.deviceID = registerReponse.deviceID;
        self.installID = registerReponse.installID;
        self.ssID = registerReponse.ssID;
        [self postNotification:BDAutoTrackNotificationDataSourceServer];
    }
}

- (void)install:(VEInstall *)install didRegisterDeviceFailWithError:(NSError *)error
{
    NSDictionary *userInfo = @{
        @"message": @"register request failure",
        @"reason": error.localizedDescription?:@"",
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterFailure
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

#if TARGET_OS_IOS
- (NSString *)identifierForVendor
{
    return [VEInstallDeviceInfo vendorID];
}

- (NSString *)identifierForTracking
{
    static NSString *identifierForTracking;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clz = NSClassFromString(@"VEInstallIDFAManager");
        SEL instanceSEL =   NSSelectorFromString(@"trackingIdentifier");
        IMP instanceIMP = [clz methodForSelector:instanceSEL];
        if (instanceIMP) {
            id (*trackingIdentifier)(id, SEL) = (void *)instanceIMP;
            identifierForTracking = trackingIdentifier(clz,instanceSEL);
        }
    });
    return identifierForTracking;
}

#endif
@end
