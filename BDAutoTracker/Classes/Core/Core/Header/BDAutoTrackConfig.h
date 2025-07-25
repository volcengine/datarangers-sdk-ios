//
//  BDAutoTrackConfig.h
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"
#import "BDCommonEnumDefine.h"
#import "BDAutoTrackEncryptionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackConfig : NSObject

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy, nullable) NSString *appName;

@property (nonatomic, copy) NSString *appID;

@property (nonatomic, copy) BDAutoTrackServiceVendor serviceVendor;

@property (nonatomic) BOOL enableH5Bridge;

@property (nonatomic) BOOL enableDeferredALink;

@property (nonatomic, copy) NSArray<NSString *> *H5BridgeAllowedDomainPatterns;

@property (nonatomic) BOOL clearABCacheOnUserChange;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *HTTPHeaderFields;

@property (nullable, nonatomic, copy) NSDictionary<NSString*, NSString *> *_Nullable (^setHTTPHeaderFieldsBlock)(void);

@property (nonatomic) BOOL trackCrashEnabled;

@property (nonatomic, assign) BOOL H5BridgeDomainAllowAll;

@property (nonatomic, assign) BOOL useBridgeUpdateUUIDEnabled;

@property (nonatomic, readonly) NSDictionary<id, id> *launchOptions;

@property (nonatomic, weak) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

@property (nonatomic, assign) BDAutoTrackEncryptionType encryptionType;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)configWithAppID:(NSString *)appID launchOptions:(nullable NSDictionary<id,id> *)launchOptions APPLOG_API_AVALIABLE(6.0.0);

@property (nonatomic, assign) BOOL devToolsEnabled;

@property (nonatomic, assign) BOOL newUserMode;

@property (nonatomic, assign) BOOL isAbTestExposureEventRepeatEnabled;

@end





@interface BDAutoTrackConfig (API_DEPRECATED)

+ (instancetype)configWithAppID:(NSString *)appID APPLOG_API_DEPRECATED_WITH_REPLACEMENT("configWithAppID:launchOptions:");

@property (nonatomic, copy, nullable) NSString *initialUserUniqueID APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use BDAutoTrack.setCurrentUserUniqueID:withType Instead");

@property (nonatomic, copy, nullable) NSString *initialUserUniqueIDType APPLOG_API_DEPRECATED_WITH_REPLACEMENT("use BDAutoTrack.setCurrentUserUniqueID:withType Instead");

@property (nonatomic, assign) BOOL rollback;


@end

NS_ASSUME_NONNULL_END
