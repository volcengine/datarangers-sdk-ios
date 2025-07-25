//
//  BDAutoTrackConfig.m
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackConfig.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackConfig+AppLog.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrackUtility.h"

@interface BDAutoTrackConfig ()

@property (nonatomic, copy) NSDictionary<id, id> *launchOptions;

@property (nonatomic, copy, nullable) NSString *initialUserUniqueID;

@property (nonatomic, copy, nullable) NSString *initialUserUniqueIDType;

@property (nonatomic, assign) BOOL rollback;

@property (nonatomic, strong) NSString *parseAppID;

@end

@implementation BDAutoTrackConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channel = @"App Store";
        self.appName = bd_sandbox_appName();
        self.serviceVendor = [RangersAppLogConfig sharedInstance].defaultVendor ?: @"";
        self.logNeedEncrypt = YES;
        self.showDebugLog = NO;
        self.H5BridgeAllowedDomainPatterns = @[];
        self.useBridgeUpdateUUIDEnabled = YES;
        
        self.autoTrackEnabled = YES;
        self.autoTrackEventType = BDAutoTrackDataTypePage | BDAutoTrackDataTypeClick;
        self.H5AutoTrackEnabled = YES;
        
        self.abEnable = YES;
        
        self.autoFetchSettings = YES;
        self.enableDeferredALink = NO;
        self.clearABCacheOnUserChange = YES;
        
        self.trackEventEnabled = YES;
        
        self.trackCrashEnabled = NO;
        self.devToolsEnabled = NO;
        self.launchTerminateEnable = YES;
        
        self.encryptionType = BDAutoTrackEncryptionTypeDefault;
        
        self.isAbTestExposureEventRepeatEnabled = YES;
    }
    
    return self;
}

- (NSString *)appID {
    NSString *aid = _appID;
    if ([aid hasPrefix:@"rangers://"]) {
        if (self.parseAppID.length > 0) {
            return self.parseAppID;
        }
        @try {
            NSURL *aidUrl = [NSURL URLWithString:aid];
            NSString *aidBase64 = [[aidUrl.path stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByRemovingPercentEncoding];
            NSString *aidMd5 = aidUrl.host;
            if (aidBase64.length > 0 && aidMd5.length > 0) {
                NSString *parserAid = ral_base64_string(aidBase64);
                if ([bd_calc_md5([parserAid UTF8String]) caseInsensitiveCompare:aidMd5] == NSOrderedSame) {
                    self.parseAppID = parserAid;
                    return parserAid;
                }
            }
        } @catch (NSException *exception) {
            return aid;
        }
    }
    return aid;
}

+ (instancetype)configWithAppID:(NSString *)appID launchOptions:(NSDictionary<id, id> *)launchOptions {
    BDAutoTrackConfig *config = [[self alloc] init];
    config.appID = appID;
    config.launchOptions = launchOptions;
    return config;
}

+ (instancetype)configWithAppID:(NSString *)appID {
    BDAutoTrackConfig *config = [self new];
    config.appID = appID;
    
    return config;
}

+ (instancetype)configWithSecondAppID:(NSString *)appID {
    BDAutoTrackConfig *config = [[self alloc] init];
    config.appID = appID;
    config.autoFetchSettings = NO;
    
    return config;
}

@end
