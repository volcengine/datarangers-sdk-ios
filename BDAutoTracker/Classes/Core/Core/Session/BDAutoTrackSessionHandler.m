//
//  BDAutoTrackSessionHandler.m
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSessionHandler.h"
#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackPlaySessionHandler.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackMacro.h"
#import "NSDictionary+VETyped.h"

static NSString * const kBDAutoTrackPreviousSessionID   = @"original_session_id";
static NSString * const kBDAutoTrackUUIDChanged         = @"uuid_changed";
static NSString * const kBDAutoTrackBackground          = @"is_background";

@interface BDAutoTrackSessionHandler()

@property (nonatomic, assign) CFTimeInterval sessionStartTime;
@property (nonatomic, assign) BOOL sessionStart;
@property (nonatomic, strong) BDAutoTrackPlaySessionHandler *playSessionHandler;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (atomic, copy) NSString *sessionID;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *storedLaunch;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *storedTerminate;

@property (nonatomic, copy) NSString *previousSessionID;
@property (nonatomic, assign) BOOL uuidChanged;

/// 标记本次启动是被动启动
@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;
/// 标记是否要把启动事件标记为被动启动。初始值同launchedPassively，应用进入前台时无条件置为NO。
@property (nonatomic) BOOL shouldMarkLaunchedPassively;
/// 标记是否要把启动事件标记为从后台恢复，也就是热启动和冷启动，第一次是冷启动，后面一直是热启动
@property (nonatomic) BOOL shouldMarkLaunchedResumeFromBackground;
@end

@implementation BDAutoTrackSessionHandler

+ (instancetype)sharedHandler {
    static BDAutoTrackSessionHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [self new];
#if TARGET_OS_IOS
        BOOL isLaunchedPassively = (UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever);
        if (!isLaunchedPassively) {
            isLaunchedPassively = (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground);
        }
#else
        BOOL isLaunchedPassively = NO;
#endif
        
        handler.launchedPassively = isLaunchedPassively;
        handler.shouldMarkLaunchedPassively = isLaunchedPassively;
        handler.shouldMarkLaunchedResumeFromBackground = NO;

#ifdef DEBUG
        NSLog(@"[yq-debug]isLaunchedParssively:%@", @(handler.isLaunchedPassively));
#endif
    });

    return handler;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if(self) {
        
#if TARGET_OS_IOS
        /* @selector(onWillEnterForeground) */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        /* @selector(onDidEnterBackground) */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
#elif TARGET_OS_OSX
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:NSApplicationWillBecomeActiveNotification
                                                   object:nil];
        
        /* @selector(onDidEnterBackground) */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:NSApplicationDidResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
#endif
        /// InitialState 只有一次
        self.launchFrom = BDAutoTrackLaunchFromInitialState;
        self.semaphore = dispatch_semaphore_create(1);
        self.storedLaunch = [NSMutableArray new];
        self.storedTerminate = [NSMutableArray new];
        self.sessionStartTime = bd_currentIntervalValue();
        self.sessionStart = NO;
        NSString *sessionID = bd_UUID();
        self.sessionID = sessionID;
        self.previousSessionID = sessionID;
        self.playSessionHandler = [[BDAutoTrackPlaySessionHandler alloc] init];
        self.uuidChanged = NO;
    }

    return self;
}

/// 应用即将进入前台时被调用
- (void)onWillEnterForeground {
    // 若应用是被动启动，则此时一般为用户点击通知，或点击屏幕上的应用按钮进入了应用。
    // 此时应用已进入前台，用户开始正常使用应用
    // 所以不再把启动事件标记为被动启动
    self.shouldMarkLaunchedPassively = NO;
    
    /// atomic只能保证不野，但是不够保证逻辑没问题
    BDSemaphoreLock(self.semaphore);
    /// 需要记录一个terminate事件并且开始新的session
    if (self.launchFrom != BDAutoTrackLaunchFromInitialState) {
        [self stopSessionInternal];
    }
    if (!self.sessionStart) {
        self.launchFrom = BDAutoTrackLaunchFromBackground;
        [self startSessionWithIDChange:YES];
    }
    BDSemaphoreUnlock(self.semaphore);
}

- (void)onDidEnterBackground {
    BDSemaphoreLock(self.semaphore);
    [self stopSessionInternal];
    BDSemaphoreUnlock(self.semaphore);
    self.launchFrom = BDAutoTrackLaunchFromInitialState;
    self.uuidChanged = NO;
}

- (void)onUUIDChanged {
    self.uuidChanged = YES;
    BDSemaphoreLock(self.semaphore);
    self.shouldMarkLaunchedResumeFromBackground = NO;
    [self stopSessionInternal];
    BDSemaphoreUnlock(self.semaphore);
}

- (void)createUUIDChangeSession {
    BDSemaphoreLock(self.semaphore);
    [self startSessionWithIDChange:NO];
    BDSemaphoreUnlock(self.semaphore);
}


#pragma mark -  session
/// SDK启动埋点时调用一次
/// caller: [BDAutoTrack startTrack]
- (BOOL)checkAndStartSession {
    /// atomic只能保证不野，但是不够保证逻辑没问题
    /// 启动app时的session创建，一次生命周期内有且仅有一次
    BDSemaphoreLock(self.semaphore);
    BOOL sessionStart = self.sessionStart;
    if (!self.sessionStart) {
        [self startSessionWithIDChange:YES];
    }
    
    /* 如果是被动启动，则立即停止Session */
    if (self.shouldMarkLaunchedPassively) {
        [self stopSessionInternal];
        self.launchFrom = BDAutoTrackLaunchFromInitialState;
    }
    BDSemaphoreUnlock(self.semaphore);

    return sessionStart;
}

- (void)startSessionWithIDChange:(BOOL)change {
    self.sessionStart = YES;
    if (change) {
        NSString *sessionID = bd_UUID();
        self.sessionID = sessionID;
        self.previousSessionID = sessionID;
    }
    [self trackLaunchEvent];
    // 这里track 一下是为了占位，如果 意外情况 不是杀进程或者退出 没有track 到 TerminateEvent就只能这样了
    // 如果正常情况下 stopSessionInternal 会 覆盖此次 event
    // zhuyuanqing: 如果这里占位，那么很容易上报duration = 0的Terminate事件。
    // 即使杀进程, Terminate也会被记录。其它特殊情况忽略。
//    [self trackTerminateEvent];
}

- (void)stopSessionInternal {
    if (self.sessionStart) {
        self.sessionStart = NO;
        [self.playSessionHandler stopPlaySession];
        [self trackTerminateEvent];
        /// 结束的时候生成一个new ID
        self.sessionID = bd_UUID();
    }
}

#pragma mark - track launch / terminate event

- (void)trackLaunchEvent {
    NSString *sessionID = self.sessionID;
    NSNumber *currentInterval = bd_currentInterval();
    NSString *startTime = bd_dateNowString();
    self.sessionStartTime = currentInterval.doubleValue;

    NSMutableDictionary *launch = [NSMutableDictionary dictionary];
    [launch setValue:sessionID forKey:kBDAutoTrackEventSessionID];

    [launch setValue:startTime forKey:kBDAutoTrackEventTime];

    long long currentIntervalMS = currentInterval.doubleValue * 1000;
    [launch setValue:@(currentIntervalMS) forKey:kBDAutoTrackLocalTimeMS];
    [launch setValue:@(currentInterval.longLongValue) forKey:@"start_timestamp"];
    [launch setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion];
    BOOL uuidChanged = self.uuidChanged;
    if (uuidChanged) {
        [launch setValue:self.previousSessionID forKey:kBDAutoTrackPreviousSessionID];
        [launch setValue:@(uuidChanged) forKey:kBDAutoTrackUUIDChanged];
    }

    // 标记冷启动，第一次肯定不是，resume_from_background=false
    // 数据流侧要求，为了数据流不做修改，新增字段放到 extra 中可以透传
    [launch setValue:@(self.shouldMarkLaunchedResumeFromBackground) forKey:kBDAutoTrackResumeFromBackground];
    // 后续所有launch均为热启动，resume_from_background=true
    self.shouldMarkLaunchedResumeFromBackground = YES;
    
    /* passive launch mark
     * mark it only if it's TRUE
     */
    if (self.shouldMarkLaunchedPassively) {
        [launch setValue:@(self.shouldMarkLaunchedPassively) forKey:kBDAutoTrackIsBackground];
    }

    [BDAutoTrack trackLaunchEventWithData:launch];
    [self.playSessionHandler startPlaySessionWithTime:startTime];
    [self.storedLaunch addObject:launch];
}

- (void)trackTerminateEvent {
    NSNumber *currentInterval = bd_currentInterval();
    NSString *now = bd_dateNowString();

    NSString *sessionID = self.sessionID;
    NSInteger duration = (NSInteger)(currentInterval.doubleValue - self.sessionStartTime);
    duration = MAX(0, duration);

    NSMutableDictionary *terminate = [NSMutableDictionary dictionary];
    [terminate setValue:sessionID forKey:kBDAutoTrackEventSessionID];
    [terminate setValue:now forKey:kBDAutoTrackEventTime];
    [terminate setValue:@(duration) forKey:@"duration"];

    long long currentIntervalMS = currentInterval.doubleValue * 1000;
    [terminate setValue:@(currentIntervalMS) forKey:kBDAutoTrackLocalTimeMS];
    [terminate setValue:@(currentInterval.longLongValue) forKey:@"stop_timestamp"];
    [terminate setValue:@(self.launchFrom) forKey:@"launch_from"];
    [terminate setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion];
    BOOL uuidChanged = self.uuidChanged;
    if (uuidChanged)  {
        NSString *previousSessionID = self.previousSessionID;
        if (![sessionID isEqualToString:previousSessionID]) {
            [terminate setValue:previousSessionID forKey:kBDAutoTrackPreviousSessionID];
        }
        [terminate setValue:@(uuidChanged) forKey:kBDAutoTrackUUIDChanged];
    }
    
    [BDAutoTrack trackTerminateEventWithData:terminate];
    /// remove last
    NSDictionary *old = self.storedTerminate.lastObject;
    if ([old isKindOfClass:[NSDictionary class]]) {
        if ([[old vetyped_stringForKey:kBDAutoTrackEventSessionID] isEqualToString:sessionID]) {
            [self.storedTerminate removeLastObject];
        }
    }
    [self.storedTerminate addObject:terminate];
}

- (NSArray *)previousLaunchs {
    BDSemaphoreLock(self.semaphore);
    NSArray *previous = [self.storedLaunch copy];
    BDSemaphoreUnlock(self.semaphore);

    return previous;
}

- (NSArray *)previousTerminates {
    BDSemaphoreLock(self.semaphore);
    NSArray *previous = [self.storedTerminate copy];
    BDSemaphoreUnlock(self.semaphore);

    return previous;
}

@end
