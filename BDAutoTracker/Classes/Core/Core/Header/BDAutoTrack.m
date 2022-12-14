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

/* ????????????ALink????????????????????????????????? config ???????????? */
@property (nonatomic, assign) BOOL enableDeferredALink;

@property (nonatomic, strong) BDAutoTrackDurationEventManager *durationEventManager;

/*! @abstract Define custom encryption method (or custom encryption key)
 @discussion SDK???????????????????????????????????????????????????SDK??????????????????????????????????????????????????????
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

    CFTimeInterval current = CFAbsoluteTimeGetCurrent();  // ?????????????????????
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
        self.started = NO;  // ????????????NO, startTrack?????????YES??? ?????????????????????BDAutoTrack????????????startTrack?????????
        self.gameModeEnable = config.gameModeEnable;
        
        // ????????????
        NSString *appID = config.appID;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.track_%@", appID];
        self.serialQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        
        // ?????? Debug Log
        self.showDebugLog = config.showDebugLog;
        
        // ????????????????????????
        self.durationEventManager = [BDAutoTrackDurationEventManager createByAppId:appID];
        
        
        
        // ??????H5 Bridge
        if (config.enableH5Bridge) {
            [[BDAutoTrackH5Bridge sharedInstance] swizzleWKWebViewMethodForJSBridge];
        }
        
        self.clearABCacheOnUserChange = config.clearABCacheOnUserChange;
        
        if (config.H5AutoTrackEnabled) {
            if ([WKWebView respondsToSelector:@selector(swizzleForH5AutoTrack)]) {
                [WKWebView performSelector:@selector(swizzleForH5AutoTrack)];
            }
        }
        
        // ????????????dataCenter?????????startTrack?????????????????? eventV3
        BDAutoTrackDataCenter *dataCenter = [[BDAutoTrackDataCenter alloc] initWithAppID:appID associatedTrack:self];
        dataCenter.showDebugLog = config.showDebugLog;
        self.dataCenter = dataCenter;
        
        // BDAutoTrack???????????????service
        self.serviceName = BDAutoTrackServiceNameTracker;
        // ???????????????????????????????????????????????????????????????BDAutoTrack??????
        [[BDAutoTrackServiceCenter defaultCenter] registerService:self];
        
        // ???????????????????????????????????????
        [[BDAutoTrackEnviroment sharedEnviroment] startTrack];
        
#if TARGET_OS_IOS
        
        // ????????? Alink??????????????????????????????????????????????????????????????????alink????????????????????????????????????????????????????????????
        self.alinkActivityContinuation = [[BDAutoTrackALinkActivityContinuation alloc] initWithAppID:self.appID];
        /* ??????????????????????????????????????????????????????????????????????????????????????????????????? */
        if (config.enableDeferredALink &&
            config.launchOptions == nil &&
            [[BDAutoTrackDefaults defaultsWithAppID:self.appID] isAPPFirstLaunch]) {
            id __block observer = [NSNotificationCenter.defaultCenter addObserverForName:BDAutoTrackNotificationRegisterSuccess object:nil queue:nil usingBlock:^(NSNotification * _Nonnull noti) {
                /* ??????????????????????????????????????????????????????????????????????????????????????????????????? */
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
        
        
        //??????
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
        
        // ?????????????????????????????????????????????
        __weak typeof(self) wself = self;
        dispatch_async(self.serialQueue, ^{
            
            BDAutoTrackRemoteSettingService *remote = [[BDAutoTrackRemoteSettingService alloc] initWithAppID:appID];
            remote.autoTrackEnabled = config.autoTrackEnabled;
            [remote registerService];
            
            wself.servicesRegistered = YES;
            
            // ?????????????????????Profile??????
            [wself.profileReporter sendProfileTrack];
        });
    }
    
    CFTimeInterval sdkInitDuration = CFAbsoluteTimeGetCurrent() - current;  // ?????????????????????
    [self.monitorAgent trackMetrics:BDroneUsageInitialization value:@(sdkInitDuration*1000) category:BDroneUsageCategory dimensions:@{}];

    return self;
}

#pragma mark - service ??????

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

#pragma mark - ??????SDK

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

/// ????????????????????????tracker??????
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
        
        // ??????session???launch???terminate???????????????
        
        if (sessionStart) {
            // ?????????????????????????????????????????????Session?????????????????????????????????????????????????????????????????? launch ??? terminate??????????????????????????????????????????????????????????????????
            NSArray *previousLaunchs = [BDAutoTrackSessionHandler sharedHandler].previousLaunchs;
            for (NSDictionary *launch in previousLaunchs) {
                [self.dataCenter trackLaunchEventWithData:[[NSMutableDictionary alloc] initWithDictionary:launch copyItems:YES]];
            }
            NSArray *previousTerminates = [BDAutoTrackSessionHandler sharedHandler].previousTerminates;
            for (NSDictionary *terminate in previousTerminates) {
                [self.dataCenter trackTerminateEventWithData:[[NSMutableDictionary alloc] initWithDictionary:terminate copyItems:YES]];
            }
        }
        
        // ???????????????????????????
        BDAutoTrackBatchService *batchService = [[BDAutoTrackBatchService alloc] initWithAppID:appID];
        [batchService registerService];
        
        // ??????????????????
        [self sendRegisterRequestWithRegisteringUserUniqueID:nil];
    });
    CFTimeInterval duration = CFAbsoluteTimeGetCurrent() - startTime;  // ?????????????????????
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
        && uniqueID.length == 0) {  //??????????????????
        return NO;
    }
    if ([oldUniqueID isEqualToString:uniqueID]) {   //??????????????????
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
        /* ?????????????????????????????????????????????launch??????????????? "$is_first_time": "true" ?????????????????? */
        [[BDAutoTrackDefaults defaultsWithAppID:self.appID] refreshIsUserFirstLaunch];
    });
    
    return YES;
}

- (void)clearUserUniqueID {
    [self setCurrentUserUniqueID:nil withType:nil];
}

- (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(NSString *)registeringUserUniqueID {
    // ?????????????????????????????????????????????
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

#pragma mark - ????????????
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
        // trace: ??????BlockList Block?????????????????????
        RL_WARN(appID, @"[PROCESS] terminate due to EVENT IN BLOCK LIST. (%@)",event);
        return NO;
    }
    
    // ensure params is a JSON Object
    if (params && ![NSJSONSerialization isValidJSONObject:params]) {
        RL_WARN(appID, @"[PROCESS] terminate due to INVALID JSON. (%@)",event);
        // trace: ???JSON????????????????????????????????????
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


#pragma mark - ????????????????????????
- (NSString *)rangersDeviceID {
    return self.identifier.deviceID;
}

- (NSString *)installID {
    return self.identifier.installID;
}

- (NSString *)ssID {
    return self.identifier.ssID;
}

/* ??????LocalConfig???????????? */
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

/// ??????UserUniqueID????????????????????????????????????????????????Settings?????????
/// @param uniqueID user unique ID
- (void)impl_setUserUniqueID:(NSString *)uniqueID oldUserUniqueID:(NSString *)oldUniqueID {
    BOOL isAnonymousUser = oldUniqueID == nil;
    
    /* 1. Stop current session
     Thread note: put in dataCenter's queue for adding userUniqueID param for the Terminate event
     */
    //remove to sync setuuid
//    [[BDAutoTrackSessionHandler sharedHandler] onUUIDChanged];
    
    /* 2. Batch report (????????????)
     * ??????????????????Session?????????
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
