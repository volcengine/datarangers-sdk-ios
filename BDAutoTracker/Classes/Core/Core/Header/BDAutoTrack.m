//
//  BDTracker.m
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Private.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackABTest.h"
#import "BDAutoTrackLocalConfigService.h"
#import "RangersLog.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackBatchService.h"

#import "BDAutoTrackABTestRequest.h"
#import "BDAutoTrackSettingsRequest.h"
#import "BDAutoTrackDataCenter.h"

#import "BDAutoTrackMacro.h"
#import "BDAutoTrackReachability.h"
#import "BDAutoTrackBatchTimer.h"

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackH5Bridge.h"
#import "BDAutoTrackALinkActivityContinuation.h"
#import "BDAutoTrackNotifications.h"
#import "BDCommonDefine.h"

#if __has_include("WKWebView+AutoTrack.h")
#import "WKWebView+AutoTrack.h"
#endif

#import "BDAutoTrackEncryptionDelegate.h"
#import "RangersLog.h"
#import "RangersLogManager.h"

#import "BDAutoTrackApplication.h"
#import "BDAutoTrackDurationEvent.h"

#import "BDroneMonitorAgent.h"

#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrackIdentifier.h"

@interface BDAutoTrack ()<BDAutoTrackService>

@property (nonatomic, strong) NSLock *syncLocker;

@property (nonatomic, strong) BDAutoTrackConfig *config;

@property (nonatomic, strong) BDAutoTrackIdentifier *identifier;

@property (nonatomic, strong) BDroneMonitorAgent *monitorAgent;

@property (nonatomic, strong) BDAutoTrackABTest *abtestManager;;

@property (class, nonatomic, strong) id<BDAutoTrackEncryptionDelegate> bdEncryptor;

@property (nonatomic, strong) NSMutableSet *ignoredPageClasses;
@property (nonatomic, strong) NSMutableSet *ignoredClickViewClasses;

@property (nonatomic, copy) NSString* appID;
@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, assign) BOOL showDebugLog;
@property (nonatomic, assign) BOOL gameModeEnable;
@property (nonatomic) BOOL clearABCacheOnUserChange;
@property (nonatomic, strong) BDAutoTrackDataCenter *dataCenter;

@property (atomic, strong) BDAutoTrackABTestRequest *abtestRequest;

@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL servicesRegistered;

@property (nonatomic, strong) BDAutoTrackLocalConfigService *localConfig;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, copy) BDAutoTrackEventPolicy (^eventHandler)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties);
@property (nonatomic, assign) NSUInteger eventHandlerTypes;


/// ALink Owner
@property (nonatomic, strong) BDAutoTrackALinkActivityContinuation *alinkActivityContinuation API_UNAVAILABLE(macos);

/* 是否开启ALink的延迟场景。初始化时从 config 上同步。 */
@property (nonatomic, assign) BOOL enableDeferredALink;

@property (nonatomic, strong) BDAutoTrackDurationEventManager *durationEventManager;

/*! @abstract Define custom encryption method (or custom encryption key)
 @discussion SDK不持有该对象。传入前须确保该对象在SDK使用期间不被释放，请勿传入临时对象。
 SDK will not hold the delegate. Please ensure the delegate's liveness during SDK's usage. Do not pass temporary object.
 */
@property (nonatomic, weak) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

@end

@implementation BDAutoTrack

+ (NSString *)SDKVersion {
    NSString *SDKVersion = [NSString stringWithFormat:@"%zd.%zd.%zd", BDAutoTrackerSDKMajorVersion, BDAutoTrackerSDKMinorVersion, BDAutoTrackerSDKPatchVersion];
    return SDKVersion;
}

+ (void)initialize
{
    Class encryptorCls = NSClassFromString(@"BDAutoTrackEncryptor");
    if (encryptorCls) {
        self.bdEncryptor = [[encryptorCls alloc] init];
    }
}

static id<BDAutoTrackEncryptionDelegate> gEncryptor;
+ (void)setBdEncryptor:(id<BDAutoTrackEncryptionDelegate>)encryptor
{
    gEncryptor = encryptor;
}

+ (id<BDAutoTrackEncryptionDelegate>)bdEncryptor
{
    return gEncryptor;
}

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config {

    CFTimeInterval current = CFAbsoluteTimeGetCurrent();  // 初始化计时开始
    if (config.showDebugLog) {
        [RangersLogManager enableModule:config.appID];
    }
    RL_DEBUG(config.appID,@"[API] BDAutoTrack initWithConfig");
    self = [self initWithAppID:config.appID];
    if (self) {
        
        if (config.monitorEnabled) {
            self.monitorAgent = [BDroneMonitorAgent agentWithTracker:self];
            [self.monitorAgent presetAggregation];
        }
        
        self.config = config;
        self.syncLocker = [NSLock new];
        self.ignoredPageClasses = [NSMutableSet new];
        self.ignoredClickViewClasses = [NSMutableSet new];
        self.started = NO;  // 初始化为NO, startTrack中置为YES。 从而保证同一个BDAutoTrack实例不会startTrack两次。
        self.gameModeEnable = config.gameModeEnable;
        
        // 创建队列
        NSString *appID = config.appID;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.track_%@", appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        
        // 设置 Debug Log
        self.showDebugLog = config.showDebugLog;
        
        // 创建时长统计管理
        self.durationEventManager = [BDAutoTrackDurationEventManager createByAppId:appID];
        
        
        
        // 设置H5 Bridge
        if (config.enableH5Bridge) {
            [[BDAutoTrackH5Bridge sharedInstance] swizzleWKWebViewMethodForJSBridge];
        }
        
        self.clearABCacheOnUserChange = config.clearABCacheOnUserChange;
        
        if (config.H5AutoTrackEnabled) {
            if ([WKWebView respondsToSelector:@selector(swizzleForH5AutoTrack)]) {
                [WKWebView performSelector:@selector(swizzleForH5AutoTrack)];
            }
        }
        
        // 先初始化dataCenter，避免startTrack之前用户调用 eventV3
        BDAutoTrackDataCenter *dataCenter = [[BDAutoTrackDataCenter alloc] initWithAppID:appID associatedTrack:self];
        dataCenter.showDebugLog = config.showDebugLog;
        self.dataCenter = dataCenter;
        
        // BDAutoTrack实例是一个service
        self.serviceName = BDAutoTrackServiceNameTracker;
        // 注册到服务中心，以后可以通过服务中心获取到BDAutoTrack实例
        [[BDAutoTrackServiceCenter defaultCenter] registerService:self];
        
        // 启动环境状态变化检测｜网络
        [[BDAutoTrackEnviroment sharedEnviroment] startTrack];
        
#if TARGET_OS_IOS
        
        // 初始化 Alink（之前是延迟初始化，由于在子线程上报中会读取alink参数，存在并发问题，所以这里提前初始化）
        self.alinkActivityContinuation = [[BDAutoTrackALinkActivityContinuation alloc] initWithAppID:self.appID];
        /* 当是应用生命周期首次启动，且是直接点击按钮启动时，执行延迟深度链接 */
        if (config.enableDeferredALink &&
            config.launchOptions == nil &&
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch]) {
            id __block observer = [NSNotificationCenter.defaultCenter addObserverForName:BDAutoTrackNotificationRegisterSuccess object:nil queue:nil usingBlock:^(NSNotification * _Nonnull noti) {
                /* 延迟归因请求依赖设备注册服务。首启无缓存，需阻塞等待设备注册完成。 */
                NSString *appId = self.appID;
                NSString *notiAppId = noti.userInfo[@"AppID"];
                if (![appId isEqualToString:notiAppId]) {
                    return;
                }
                if ([noti.userInfo[kBDAutoTrackNotificationDataSource] isEqualToString:BDAutoTrackNotificationDataSourceServer]) {
                    [self.alinkActivityContinuation continueDeferredALinkActivityWithRegisterUserInfo:noti.userInfo];
                    [NSNotificationCenter.defaultCenter removeObserver: observer];
                }
            }];
        }
        self.enableDeferredALink = config.enableDeferredALink;
        
        
        //曝光
        Class clz = NSClassFromString(@"BDAutoTrackExposureManager");
        SEL instanceSEL =   NSSelectorFromString(@"sharedInstance");
        IMP instanceIMP = [clz methodForSelector:instanceSEL];
        if (instanceIMP) {
            id (*sharedInstance)(id, SEL) = (void *)instanceIMP;
            id manager = sharedInstance(clz,instanceSEL);
            SEL startSEL = NSSelectorFromString(@"startWithTracker:");
            IMP startIMP = [manager methodForSelector:startSEL];
            if (startIMP) {
                void (*startWithTracker)(id, SEL, id) = (void *)startIMP;
                startWithTracker(manager,startSEL,self);
            }
        }
        
        
#endif
        
        
        self.encryptionDelegate = config.encryptionDelegate;
        /*
         *  LocalSetting processed synchronously in the initialization thread
         *  fengchengqi @ 2022-01-11
         */
        BDAutoTrackLocalConfigService *localSettings = [[BDAutoTrackLocalConfigService alloc] initWithConfig:config];
        [localSettings registerService];
        localSettings.enableH5Bridge = config.enableH5Bridge;
        localSettings.H5BridgeDomainAllowAll = config.H5BridgeDomainAllowAll;
        localSettings.H5BridgeAllowedDomainPatterns = config.H5BridgeAllowedDomainPatterns;
        
        //identifier
        self.identifier = [[BDAutoTrackIdentifier alloc] initWithConfig:config];

        if ([[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch] && self.identifier.userUniqueID == nil) {
            self.identifier.userUniqueID = config.initialUserUniqueID;
            self.identifier.userUniqueIDType = config.initialUserUniqueIDType;
        }
        
        self.localConfig = localSettings;
        
        //abtest
        self.abtestManager = [[BDAutoTrackABTest alloc] initWithAppID:appID];
        self.abtestManager.manualPullInterval = 10.0f;
        self.abtestManager.abtestEnabled = config.abEnable;
        
        // 各服务注册到服务中心，任务入队
        __weak typeof(self) wself = self;
        dispatch_async(self.serialQueue, ^{
            
            BDAutoTrackRemoteSettingService *remote = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:appID];
            remote.autoTrackEnabled = config.autoTrackEnabled;
            [remote registerService];
            
            wself.servicesRegistered = YES;
            
            // 冷启动上报一次Profile事件
            [wself.profileReporter sendProfileTrack];
        });
    }
    
    CFTimeInterval sdkInitDuration = CFAbsoluteTimeGetCurrent() - current;  // 初始化计时结束
    [self.monitorAgent trackMetrics:BDroneUsageInitialization value:@(sdkInitDuration*1000) category:BDroneUsageCategory dimensions:@{}];

    return self;
}

#pragma mark - service 协议

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = [appID mutableCopy];
        [BDAutoTrackSessionHandler sharedHandler];
        [BDAutoTrackApplication shared];
        
        Class cls_BDAutoTrackASA = NSClassFromString(@"BDAutoTrackASA");
        if (cls_BDAutoTrackASA && [cls_BDAutoTrackASA respondsToSelector:@selector(start)] &&
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch]) {
            [cls_BDAutoTrackASA performSelector:@selector(start)]; // RegisterRequest expects we get ASA attribution as soon as possible
        }
    }
    return self;
}

- (void)registerService {
}

- (BOOL)serviceAvailable {
    return YES;
}

- (void)unregisterService {
}

#pragma mark - 启动SDK

+ (instancetype)trackWithConfig:(BDAutoTrackConfig *)config {
    
    
    NSString *appID = config.appID;
    if (![appID isKindOfClass:[NSString class]] || appID.length < 1) {
        return nil;
    }
    
    BDAutoTrack *tracker = [self trackWithAppID:appID];
    if (tracker == nil || ![tracker isKindOfClass:[BDAutoTrack class]]) {
        tracker = [[BDAutoTrack alloc] initWithConfig:config];
    }
    return tracker;
}

/// 从缓存获取已有的tracker实例
+ (instancetype)trackWithAppID:(NSString *)appID {
    return [[BDAutoTrackServiceCenter defaultCenter] serviceForName:BDAutoTrackServiceNameTracker appID:appID];
}

- (void)startTrack {
    if (self.started) {
        return;
    }
    RL_DEBUG(self.appID,@"[API] BDAutoTrack startTrack");
    self.started = YES;
    
    if (self.config.monitorEnabled) {
        [self.monitorAgent upload];
    }

    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *appID = self.appID;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRegisterSuccess:) name:BDAutoTrackNotificationRegisterSuccess object:nil];
    
    BOOL sessionStart = [[BDAutoTrackSessionHandler sharedHandler] checkAndStartSession];
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        
        // 开始session。launch和terminate埋点入库。
        
        if (sessionStart) {
            // 这里应该是考虑多实例的场景下，Session是全局的，如果之前已经启动了，说明已经产生了 launch 和 terminate，这里新的实例启动的时候把之前的事件补发一下
            NSArray *previousLaunchs = [BDAutoTrackSessionHandler sharedHandler].previousLaunchs;
            for (NSDictionary *launch in previousLaunchs) {
                [self.dataCenter trackLaunchEventWithData:[[NSMutableDictionary alloc] initWithDictionary:launch copyItems:YES]];
            }
            NSArray *previousTerminates = [BDAutoTrackSessionHandler sharedHandler].previousTerminates;
            for (NSDictionary *terminate in previousTerminates) {
                [self.dataCenter trackTerminateEventWithData:[[NSMutableDictionary alloc] initWithDictionary:terminate copyItems:YES]];
            }
        }
        
        // 初始化埋点上报服务
        BDAutoTrackBatchService *batchService = [[BDAutoTrackBatchService alloc] initWithAppID:appID];
        [batchService registerService];
        
        // 发送注册请求
        [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
    });
    CFTimeInterval duration = CFAbsoluteTimeGetCurrent() - startTime;  // 初始化计时结束
    [self.monitorAgent trackMetrics:BDroneUsageStartup value:@(duration*1000) category:BDroneUsageCategory dimensions:@{}];
    
}

- (void)onRegisterSuccess:(NSNotification *)noti
{
    NSString *appId = noti.userInfo[@"AppID"];
    
    if ([self.appID isEqualToString:appId]) {
        BDAutoTrackWeakSelf;
        dispatch_async(self.serialQueue, ^{
            BDAutoTrackStrongSelf;
            [self.profileReporter sendProfileTrack];
        });
        
    }
}

- (void)setUserAgent:(NSString *)userAgent {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        [bd_settingsServiceForAppID(appID) saveUserAgent:[userAgent mutableCopy]];
    });
}

- (BOOL)setCurrentUserUniqueID:(NSString *)uniqueID {
    
    return [self setCurrentUserUniqueID:uniqueID withType:nil];
}

- (BOOL)setCurrentUserUniqueID:(nullable NSString *)uniqueID withType:(nullable NSString *)type
{
    
    NSString *oldUniqueID = self.identifier.userUniqueID;
    if (oldUniqueID.length == 0
        && uniqueID.length == 0) {  //匿名态未变化
        return NO;
    }
    if ([oldUniqueID isEqualToString:uniqueID]) {   //登陆态未变化
        return NO;
    }
    [[BDAutoTrackSessionHandler sharedHandler] onUUIDChanged];
    self.identifier.ssID = @"";
    self.identifier.userUniqueID = uniqueID;
    self.identifier.userUniqueIDType = type;
    [[BDAutoTrackSessionHandler sharedHandler] createUUIDChangeSession];
    
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        [self.identifier flush];
        BDAutoTrackStrongSelf;
        [self impl_setUserUniqueID:uniqueID oldUserUniqueID:oldUniqueID];
        /* 重置首次启动判断状态机。下一次launch事件将携带 "$is_first_time": "true" 事件参数上报 */
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] refreshIsUserFirstLaunch];
    });
    
    return YES;
}

- (void)clearUserUniqueID {
    [self setCurrentUserUniqueID:nil withType:nil];
}

- (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(NSString *)registeringUserUniqueID {
    // 没有启动的状态下，什么也不做。
    if (!self.started) {
        return NO;
    }
    if ([registeringUserUniqueID length] <= 0) {
        registeringUserUniqueID = self.identifier.userUniqueID;
    }
    self.identifier.userUniqueID = registeringUserUniqueID;
    [self.identifier requestDeviceRegistration];
    return YES;
}

- (BOOL)sendRegisterRequest {
    return [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
}

- (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor {
    NSString *appID = self.appID;
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        BDAutoTrackLocalConfigService *settings = bd_settingsServiceForAppID(appID);
        BDAutoTrackServiceVendor old = settings.serviceVendor;
        if (old != serviceVendor) {
            RL_DEBUG(self.appID, @"update service vendoer. (%@ -> %@)", old, serviceVendor);
            settings.serviceVendor = serviceVendor;
            [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
        }
    });
}

#pragma mark - set Blocks
- (void)setRequestURLBlock:(BDAutoTrackRequestURLBlock)requestURLBlock {
    NSString *appID = self.appID;
    BDAutoTrackRequestURLBlock block = [requestURLBlock copy];
    dispatch_async(self.serialQueue, ^{
        bd_settingsServiceForAppID(appID).requestURLBlock = block;
    });
}

- (void)setRequestHostBlock:(BDAutoTrackRequestHostBlock)requestHostBlock {
    NSString *appID = self.appID;
    BDAutoTrackRequestHostBlock block = [requestHostBlock copy];
    dispatch_async(self.serialQueue, ^{
        bd_settingsServiceForAppID(appID).requestHostBlock = block;
    });
}

- (void)setCustomHeaderValue:(nullable id)value forKey:(NSString *)key {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackLocalConfigService *s = bd_settingsServiceForAppID(appID);
        [s setCustomHeaderValue:value forKey:key];
    });
}

- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackLocalConfigService *s = bd_settingsServiceForAppID(appID);
        [s setCustomHeaderWithDictionary:dictionary];
    });
}

- (void)removeCustomHeaderValueForKey:(NSString *)key {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackLocalConfigService *s = bd_settingsServiceForAppID(appID);
        [s removeCustomHeaderValueForKey:key];
    });
}

- (void)setCustomHeaderBlock:(BDAutoTrackCustomHeaderBlock)customHeaderBlock {
    NSString *appID = self.appID;
    BDAutoTrackCustomHeaderBlock block = [customHeaderBlock copy];
    dispatch_async(self.serialQueue, ^{
        bd_settingsServiceForAppID(appID).customHeaderBlock = block;
    });
}

#pragma mark - 埋点上报
- (BOOL)eventV3:(NSString *)event {
    return [self eventV3:event params:nil];
}

- (BOOL)eventV3:(NSString *)event params:(NSDictionary *)params {

    [self.monitorAgent trackEventCall];
    NSString *appID = self.appID;
    // guard. Ensure `event` is a NSStirng.
    if (![event isKindOfClass:[NSString class]] || event.length < 1) {
        RL_WARN(appID, @"[PROCESS] terminate due to EMPTY EVENT");
        return NO;
    }
    
    // ensure event is not blocked in batchService.blockedList
    if (bd_batchIsEventInBlockList(event, appID)) {
        // trace: 因被BlockList Block，而上报失败。
        RL_WARN(appID, @"[PROCESS] terminate due to EVENT IN BLOCK LIST. (%@)",event);
        return NO;
    }
    
    // ensure params is a JSON Object
    if (params && ![NSJSONSerialization isValidJSONObject:params]) {
        RL_WARN(appID, @"[PROCESS] terminate due to INVALID JSON. (%@)",event);
        // trace: 因JSON序列化失败，而上报失败。
        return NO;
    }
    NSDictionary *trackData = @{kBDAutoTrackEventType:[event mutableCopy],
                                kBDAutoTrackEventData:[[NSDictionary alloc] initWithDictionary:params copyItems:YES]};
    
    [self.dataCenter trackUserEventWithData:trackData];
    return YES;
}





#pragma mark - setEventHandler

- (void)setEventHandler:(BDAutoTrackEventPolicy (^)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties))handler
               forTypes:(BDAutoTrackDataType)types
{
    if (!handler) {
        return;
    }
    self.eventHandlerTypes = types;
    self.eventHandler = [handler copy];
    
}


#pragma mark - App

- (void)setAppRegion:(NSString *)appRegion {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        [bd_settingsServiceForAppID(appID) saveAppRegion:[appRegion mutableCopy]];
    });
}

- (void)setAppLauguage:(NSString *)appLauguage {
    NSString *appID = self.appID;
    dispatch_async(self.serialQueue, ^{
        [bd_settingsServiceForAppID(appID) saveAppLauguage:[appLauguage mutableCopy]];
    });
}

#pragma mark - ABTest

- (id)ABTestConfigValueForKey:(NSString *)key defaultValue:(id)defaultValue {
    BDAutoTrackABTest *ab = self.abtestManager;
    if (bd_remoteSettingsForAppID(self.appID).abTestEnabled && ab != nil) {
        return [ab getConfig:key defaultValue:defaultValue];
    }
    
    return defaultValue;
}
- (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue {
    if (self.servicesRegistered) {
        return [self ABTestConfigValueForKey:key defaultValue:defaultValue];
    }
    
    __block id value;
    __weak typeof(self) wself = self;
    dispatch_sync(self.serialQueue, ^{
        value = [wself ABTestConfigValueForKey:key defaultValue:defaultValue];
    });
    return value;
}

- (void)setExternalABVersion:(NSString *)versions {
    dispatch_async(self.serialQueue, ^{
        [self.abtestManager setExternalABVersion:[versions mutableCopy]];
    });
    
}

- (NSString *)abVids {
    return [[self.abtestManager sendableABVersions] mutableCopy];
}

- (NSString *)abVidsSync {
    if (self.servicesRegistered) {
        return [self abVids];
    }
    
    __block NSString *abVids;
    __weak typeof(self) wself = self;
    dispatch_sync(self.serialQueue, ^{
        abVids = [wself abVids];
    });
    return abVids;
}

- (NSString *)allAbVids {
    return [self.abtestManager allABVersions];
}
- (NSString *)allAbVidsSync {
    if (self.servicesRegistered) {
        return [self allAbVids];
    }
    
    __block NSString *allAbVids;
    __weak typeof(self) wself = self;
    dispatch_sync(self.serialQueue, ^{
        allAbVids = [wself allAbVids];
    });
    return allAbVids;
}

- (NSDictionary *)allABTestConfigs {
    return [self.abtestManager allABTestConfigs];
}

- (NSDictionary *)allABTestConfigs2 {
    return [self.abtestManager allABTestConfigs2];
}

- (NSDictionary *)allABTestConfigsSync {
    if (self.servicesRegistered) {
        return [self allABTestConfigs];
    }
    
    __block NSDictionary *allABTestConfigs;
    __weak typeof(self) wself = self;
    dispatch_sync(self.serialQueue, ^{
        allABTestConfigs = [wself allABTestConfigs];
    });
    return allABTestConfigs;
}

- (void)pullABTestConfigs {
    [self.abtestManager pullABTesting:YES];
}


#pragma mark - ALink

#if TARGET_OS_IOS
- (BDAutoTrackALinkActivityContinuation *)alinkActivityContinuation {
    if (!_alinkActivityContinuation) {
        _alinkActivityContinuation = [[BDAutoTrackALinkActivityContinuation alloc] initWithAppID:self.appID];
    }
    return _alinkActivityContinuation;
}

- (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate {
    if (!self.enableDeferredALink && [ALinkRoutingDelegate respondsToSelector:@selector(onAttributionData:error:)]) {
        RL_WARN(self.appID, @"[ALink] please impl @selector(onAttributionData:error:");
    }
    [self.alinkActivityContinuation setRoutingDelegate:ALinkRoutingDelegate];
}

- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    return [self.alinkActivityContinuation continueALinkActivityWithURL:ALinkURL];
}

#endif


#pragma mark - Location

+ (void)setGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude {
    [[BDAutoTrackApplication shared] updateGPSLocation:geoCoordinateSystem longitude:longitude latitude:latitude];
}


#pragma mark - DurationEvent

- (void)startDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager startDurationEvent:eventName startTimeMS:nowTimeMS];
    });
}

- (void)pauseDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager pauseDurationEvent:eventName pauseTimeMS:nowTimeMS];
    });
}

- (void)resumeDurationEvent:(NSString *)eventName {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        [self.durationEventManager resumeDurationEvent:eventName resumeTimeMS:nowTimeMS];
    });
}

- (void)stopDurationEvent:(NSString *)eventName properties:(NSDictionary *)properties {
    NSNumber * nowTimeMS = bd_milloSecondsInterval();
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackDurationEvent *durationEvent = [self.durationEventManager stopDurationEvent:eventName stopTimeMS:nowTimeMS];
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data addEntriesFromDictionary:properties];
        [data setValue:@(durationEvent.duration) forKey:kBDAutoTrackEventDuration];
        NSDictionary *trackData = @{
            kBDAutoTrackEventType: eventName,
            kBDAutoTrackEventData: data,
        };
        [self.dataCenter trackUserEventWithData:trackData];
    });
}


#pragma mark - 获取设备注册信息
- (NSString *)rangersDeviceID {
    return self.identifier.deviceID;
}

- (NSString *)installID {
    return self.identifier.installID;
}

- (NSString *)ssID {
    return self.identifier.ssID;
}

/* 获取LocalConfig服务信息 */
- (NSString *)userUniqueID {
    return self.identifier.userUniqueID;
}


#pragma mark - Flush

- (void)flush
{
    [self flushWithTimeInterval:10.0f];
}

#pragma mark - clearAllEvent
- (void)clearAllEvent
{
    [self.dataCenter clearDatabase];
}

#pragma mark - private API

/// 设置UserUniqueID的实现。需要重新发送注册、激活、Settings请求。
/// @param uniqueID user unique ID
- (void)impl_setUserUniqueID:(NSString *)uniqueID oldUserUniqueID:(NSString *)oldUniqueID {
    BOOL isAnonymousUser = oldUniqueID == nil;
    
    /* 1. Stop current session
     Thread note: put in dataCenter's queue for adding userUniqueID param for the Terminate event
     */
    //remove to sync setuuid
//    [[BDAutoTrackSessionHandler sharedHandler] onUUIDChanged];
    
    /* 2. Batch report (同步上报)
     * 上报完所有旧Session的事件
     */
    BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, self.appID);
    [service sendTrackDataFrom:BDAutoTrackTriggerSourceUUIDChanged];
    
    /* 3. Switch User.*/
    /* Clear AB cache */
    if (self.clearABCacheOnUserChange && !isAnonymousUser) {
        [self.abtestManager updateABConfigWithRawData:nil postNotification:NO];
        [self.abtestManager setExternalABVersion:nil];
        [self.abtestManager setALinkABVersions:nil];
    }
    /* clear $tr_web_ssid */
    BDAutoTrackLocalConfigService *localConfigService = bd_settingsServiceForAppID(self.appID);
    [localConfigService removeCustomHeaderValueForKey:kBDAutoTrack__tr_web_ssid];
    
    [self.identifier requestDeviceRegistration];
    
}


- (NSString *)applicationId
{
    return self.appID;
}

@end
