//
//  BDAutoTrackABTest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackABTest.h"
#import "BDAutoTrackTimer.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackABTestRequest.h"

static NSString *const kBDAutoTrackExposedVids          = @"kBDAutoTrackExposedVids";      // Array
static NSString *const kBDAutoTrackExternalVids         = @"kBDAutoTrackExternalVids";     // Array
static NSString *const kBDAutoTrackALinkABVersions      = @"kBDAutoTrackALinkABVersions";  // Stirng
static NSString *const kBDAutoTrackABTestRawDataCache   = @"kBDAutoTrackABTestRawDataCache";  // Dict


static NSString *const kBDAutoTrackABTestVid    = @"vid";
static NSString *const kBDAutoTrackABTestValue  = @"val";

@interface BDAutoTrackABTest ()

@property (nonatomic, strong) BDAutoTrackABTestRequest *request;

// 已曝光的Vid
@property (nonatomic, strong) NSMutableSet<NSString *> *exposedVids;

// 外部传来的AB Vid
@property (nonatomic, strong) NSMutableSet<NSString *> *externalVids;
// TODO: 优化为计算属性
@property (atomic, copy) NSString *externalVersions;

// 所有已曝光的Vid，包括exposedVids和externalVids。我们认为传进来的externalVids都是已曝光的。
// TODO: 优化为计算属性
@property (nonatomic, strong) NSMutableSet<NSString *> *allExposedVids;
// 就是 [self.allExposedVids.allObjects componentsJoinedByString:@","];
// TODO: 优化为计算属性
@property (atomic, copy) NSString *abVersions;

@property (nonatomic) NSString *m_alinkABVersions;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;

@end

@implementation BDAutoTrackABTest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameABTest;
        
        self.request = [[BDAutoTrackABTestRequest alloc] initWithAppID:appID];
        
        self.defaults = [BDAutoTrackDefaults defaultsWithAppID:self.appID];
        NSArray *exposedVids = [self.defaults arrayValueForKey:kBDAutoTrackExposedVids] ?: @[];
        NSArray *externalVids = [self.defaults arrayValueForKey:kBDAutoTrackExternalVids] ?: @[];
        self.m_alinkABVersions = [self.defaults stringValueForKey:kBDAutoTrackALinkABVersions];
        
        self.externalVids = [NSMutableSet setWithArray:externalVids];
        self.exposedVids = [NSMutableSet setWithArray:exposedVids];
        NSMutableSet *vids = [NSMutableSet setWithArray:externalVids];
        [vids addObjectsFromArray:exposedVids];
        self.allExposedVids = vids;
        
        self.currentRawData = [self.defaults dictionaryValueForKey:kBDAutoTrackABTestRawDataCache] ?: @{} ;
        if (vids.count > 0) {
            self.abVersions = [vids.allObjects componentsJoinedByString:@","];
        } else {
            self.abVersions = nil;
        }
        NSString *queueName = [NSString stringWithFormat:@"com.applog.abTest_%@",appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:) name:BDAutoTrackNotificationRegisterSuccess object:nil];

        if (self.currentRawData.count > 0) {
            [self postABTestNotification];
        }
        
    }
    
    return self;
}

#pragma mark property
/// warpped setter, only for public call
- (void)setALinkABVersions:(NSString *)ALinkPBABVersions {
    NSString *ALinkPBABVersions_cp = [ALinkPBABVersions copy];
    
    self.m_alinkABVersions = ALinkPBABVersions_cp;
    dispatch_async(self.serialQueue, ^{
        [self.defaults setValue:ALinkPBABVersions_cp forKey:kBDAutoTrackALinkABVersions];
        [self.defaults saveDataToFile];
    });
}


- (void)updateABConfigWithRawData:(NSDictionary<NSString *, NSDictionary *> *)rawData postNotification:(BOOL)postNoti {
    dispatch_async(self.serialQueue, ^{
        NSUInteger oldCount = self.exposedVids.count;
        self.currentRawData = rawData;

        NSMutableSet<NSString *> *allVids = [NSMutableSet new];
        [rawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            if (vid) {
                [allVids addObject:vid];
            }
        }];

        NSMutableSet<NSString *> *exposedVids = [NSMutableSet new];
        [self.exposedVids enumerateObjectsUsingBlock:^(NSString *vid, BOOL *stop) {
            if ([allVids containsObject:vid]) {
                [exposedVids addObject:vid];
            }
        }];

        [self.defaults setValue:rawData forKey:kBDAutoTrackABTestRawDataCache];
        [self.defaults setValue:exposedVids.allObjects forKey:kBDAutoTrackExposedVids];
        [self.defaults saveDataToFile];
        self.exposedVids = exposedVids;
        
        NSMutableSet<NSString *> *vids = [exposedVids mutableCopy];
        [vids addObjectsFromArray:self.externalVids.allObjects];
        self.allExposedVids = vids;
        if (vids.count > 0) {
            self.abVersions = [vids.allObjects componentsJoinedByString:@","];
        } else {
            self.abVersions = nil;
        }
        
        if (postNoti) {
            [self postABTestNotification];
            NSUInteger updateCount = exposedVids.count;
            if (oldCount != updateCount) {
                [self postChangedNotification];
            }
        }
    });
}

/// 通知。userInfo里提供服务器返回的原始数据。
- (void)postABTestNotification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *userInfo = @{kBDAutoTrackNotificationAppID: self.appID,
                                   kBDAutoTrackNotificationData:bd_trueDeepCopyOfDictionary(self.currentRawData)};
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationABTestSuccess
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

/// Impl of `ABTestConfigValueForKey: defaultValue:`
- (id)getConfig:(NSString *)key defaultValue:(id)defaultValue {
    if (!self.abtestEnabled) {
        return defaultValue;
    }
    __block id value = defaultValue;
    dispatch_sync(self.serialQueue, ^{
        NSDictionary *config = [self.currentRawData vetyped_dictionaryForKey:key];
        if ([config isKindOfClass:[NSDictionary class]]) {
            value = [config objectForKey:kBDAutoTrackABTestValue] ?: defaultValue;
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            
            if (vid.length > 0) {
                // 触发`feature变体使用事件`, 立即上报
                BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
                NSDictionary *params = @{
                    @"ab_sdk_version": vid
                };
                [track eventV3:@"abtest_exposure" params:params];
                
                // 用户访问的事件还没有曝光过，将它曝光
                if (![self.exposedVids containsObject:vid]) {
                    [self.exposedVids addObject:vid];    // 添加到曝光
                    [self.allExposedVids addObject:vid]; // 添加到全部已曝光
                    self.abVersions = [self.allExposedVids.allObjects componentsJoinedByString:@","];  // 更新事件公共参数abVersions
                    
                    // 将 self.exposedVids 存入缓存
                    [self.defaults setValue:self.exposedVids.allObjects forKey:kBDAutoTrackExposedVids];
                    [self.defaults saveDataToFile];
                    
                    // 发送通知
                    [self postChangedNotification];
                }
            }
        }
    });

    return value;
}

/// 发送 BDAutoTrackNotificationABTestVidsChanged 通知
- (void)postChangedNotification {
    NSString *vids = [self.exposedVids.allObjects componentsJoinedByString:@","];
    NSString *external = [self.externalVids.allObjects componentsJoinedByString:@","];
    NSString *appID = [self.appID mutableCopy];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:appID forKey:kBDAutoTrackNotificationAppID];
    [userInfo setValue:vids forKey:kBDAutoTrackNotificationABTestVids];
    [userInfo setValue:external forKey:kBDAutoTrackNotificationABTestExternalVids];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationABTestVidsChanged
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (NSDictionary *)allABTestConfigs {
    NSMutableDictionary *configs = [NSMutableDictionary new];

    dispatch_sync(self.serialQueue, ^{
        [self.currentRawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            id value = [config objectForKey:kBDAutoTrackABTestValue];
            [configs setValue:value forKey:key];
        }];
    });

    return configs;
}

- (NSDictionary *)allABTestConfigs2 {
    return self.currentRawData;
}

- (NSString *)allABVersions {
    NSMutableSet<NSString *> *allVids = [NSMutableSet new];

    dispatch_sync(self.serialQueue, ^{
        [self.currentRawData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *config, BOOL *stop) {
            if (![config isKindOfClass:[NSDictionary class]]) {
                return;
            }
            NSString *vid = [config vetyped_stringForKey:kBDAutoTrackABTestVid];
            if (vid) {
                [allVids addObject:vid];
            }
        }];
    });

    if (allVids.count < 1) {
        return nil;
    }

    return [allVids.allObjects componentsJoinedByString:@","];
}

- (void)setExternalABVersion:(NSString *)versions {
    NSString *oldVersion = self.externalVersions;
    if (versions.length < 1) {
        [self cleanExternalAbVersion];
        return;
    }
    /// 两个相等
    if ([oldVersion isEqualToString:versions]) {
        return;
    }
    
    self.externalVersions = versions;
    dispatch_async(self.serialQueue, ^{
        NSArray *vids = [versions componentsSeparatedByString:@","];
        NSMutableSet<NSString *> *externalVids = [NSMutableSet new];
        for (NSString *vid in vids) {
            if (vid.integerValue > 0) {
                [externalVids addObject:vid];
            }
        }
        
        NSMutableSet *allExposedVids = [self.exposedVids mutableCopy];
        [allExposedVids addObjectsFromArray:externalVids.allObjects];
        self.allExposedVids = allExposedVids;
        self.externalVids = externalVids;
        if (allExposedVids.count > 0) {
             self.abVersions = [allExposedVids.allObjects componentsJoinedByString:@","];
        } else {
            self.abVersions = nil;
        }
        
        [self.defaults setValue:externalVids.allObjects forKey:kBDAutoTrackExternalVids];
        [self.defaults saveDataToFile];
    });
}

- (void)cleanExternalAbVersion {
    dispatch_async(self.serialQueue, ^{
        self.externalVersions = nil;
        self.externalVids = [NSMutableSet set];
        self.allExposedVids = [self.exposedVids mutableCopy];
        if (self.allExposedVids.count > 0) {
             self.abVersions = [self.allExposedVids.allObjects componentsJoinedByString:@","];
        } else {
            self.abVersions = nil;
        }

        [self.defaults setValue:nil forKey:kBDAutoTrackExternalVids];
        [self.defaults saveDataToFile];
    });
}

/// AB versions network param
/// @discussion wrap a level more
/// @return abVersions + alinkABVerisons
- (NSString *)sendableABVersions {
    NSMutableArray <NSString *> *result = [[NSMutableArray alloc] init];
    
    NSString *abVersions = self.abVersions;
    NSString *alinkABVersions = self.m_alinkABVersions;
    if ([abVersions length]) {
        [result addObject:abVersions];
    }
    if ([alinkABVersions length]) {
        [result addObject:alinkABVersions];
    }
    
    NSString *result_str = [result componentsJoinedByString:@","];
    return result_str;
}

- (void)setAbtestEnabled:(BOOL)abtestEnabled
{
    if (_abtestEnabled != abtestEnabled) {
        _abtestEnabled = abtestEnabled;
        [self triggerEnabled];
    }
}

- (void)triggerEnabled
{
    NSString *timerName = [@"ab_fetcher" stringByAppendingFormat:@"_%@",self.appID];
    if (self.abtestEnabled) {
        __weak typeof(self) weak_self = self;
        dispatch_block_t action = ^{
            __strong typeof (weak_self) strong_self = weak_self;
            /// timer check
            if (strong_self) {
                [strong_self pullABTesting:NO];
            }
        };
        
        NSTimeInterval abFetchInterval = bd_remoteSettingsForAppID(self.appID).abFetchInterval;
        [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:timerName
                                                             timeInterval:abFetchInterval
                                                                    queue:nil
                                                                  repeats:YES
                                                                   action:action];
    } else {
        [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:timerName];
    }
}

- (void)onRegisterSuccess:(NSNotification *)noti
{
    if (noti.userInfo && [BDAutoTrackNotificationDataSourceServer isEqualToString:noti.userInfo[kBDAutoTrackNotificationDataSource]]) {
        [self pullABTesting:NO];
    }
}

- (void)pullABTesting:(BOOL)manually
{
    if (!self.abtestEnabled) {
        return;
    }
    if (manually) {
        long long now = CACurrentMediaTime();
        if (now - self.lastManualPullTime < self.manualPullInterval) {
            return;
        }
        self.lastManualPullTime = now;
    }
    if ([[BDAutoTrack trackWithAppID:self.appID].identifier deviceAvalible]) {
        if (manually) {
            [self.request startRequestWithRetry:0];
        } else {
            [self.request startRequestWithRetry:3];
        }
    }
}


@end
