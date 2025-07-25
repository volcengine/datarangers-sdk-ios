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

@property (nonatomic, assign) NSInteger duration;

@property (nonatomic, assign) CFTimeInterval sessionStartTime;
@property (nonatomic, assign) BOOL sessionStart;
@property (nonatomic, strong) id playSessionHandler;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (atomic, copy) NSString *sessionID;
@property (nonatomic, assign) BOOL isBackground;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *storedLaunch;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *storedTerminate;

@property (nonatomic, copy) NSString *previousSessionID;
@property (nonatomic, assign) BOOL uuidChanged;

@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;

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
#else
        BOOL isLaunchedPassively = NO;
#endif
        
        handler.launchedPassively = isLaunchedPassively;
        handler.shouldMarkLaunchedPassively = isLaunchedPassively;
        handler.shouldMarkLaunchedResumeFromBackground = NO;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
#elif TARGET_OS_OSX
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:NSApplicationWillBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:NSApplicationDidResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
#endif
        self.launchFrom = BDAutoTrackLaunchFromInitialState;
        self.duration = 0;
        self.semaphore = dispatch_semaphore_create(1);
        self.storedLaunch = [NSMutableArray new];
        self.storedTerminate = [NSMutableArray new];
        self.sessionStartTime = bd_currentIntervalValue();
        self.sessionStart = NO;
        NSString *sessionID = bd_UUID();
        self.sessionID = sessionID;
        self.previousSessionID = sessionID;
        Class handlerClass = NSClassFromString(@"BDAutoTrackPlaySessionHandler");
        if (handlerClass) {
            self.playSessionHandler = [[handlerClass alloc] init];
        }
        self.uuidChanged = NO;
        self.isBackground = NO;
    }

    return self;
}

- (void)onWillEnterForeground {
    self.shouldMarkLaunchedPassively = NO;
    
    BDSemaphoreLock(self.semaphore);
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
- (BOOL)checkAndStartSession {
    BDSemaphoreLock(self.semaphore);
    BOOL sessionStart = self.sessionStart;
    
#if TARGET_OS_IOS
    if (!self.shouldMarkLaunchedPassively) {
        self.shouldMarkLaunchedPassively = (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground);
    }
#endif

    if (!self.sessionStart) {
        [self startSessionWithIDChange:YES];
    }
    
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
        self.isBackground = NO;
    }
    [self trackLaunchEvent];
}

- (void)stopSessionInternal {
    if (self.sessionStart) {
        self.sessionStart = NO;
        if (self.playSessionHandler && [self.playSessionHandler respondsToSelector:@selector(stopPlaySession)]) {
            [self.playSessionHandler performSelector:@selector(stopPlaySession)];
        }
        [self trackTerminateEvent];
        self.sessionID = bd_UUID();
        self.isBackground = NO;
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

    [launch setValue:@(self.shouldMarkLaunchedResumeFromBackground) forKey:kBDAutoTrackResumeFromBackground];
    self.shouldMarkLaunchedResumeFromBackground = YES;

    if (self.shouldMarkLaunchedPassively) {
        [launch setValue:@(self.shouldMarkLaunchedPassively) forKey:kBDAutoTrackIsBackground];
        self.isBackground = self.shouldMarkLaunchedPassively;
    } else {
        self.isBackground = NO;
    }

    [BDAutoTrack trackLaunchEventWithData:launch];
    
    if (self.playSessionHandler && [self.playSessionHandler respondsToSelector:@selector(startPlaySessionWithTime:)]) {
        [self.playSessionHandler performSelector:@selector(startPlaySessionWithTime:) withObject:startTime];
    }
    [self.storedLaunch addObject:launch];
}

- (void)trackTerminateEvent {
    NSNumber *currentInterval = bd_currentInterval();
    NSString *now = bd_dateNowString();

    NSString *sessionID = self.sessionID;
    double durationDuration = currentInterval.doubleValue - self.sessionStartTime;
    NSInteger duration = (NSInteger)(durationDuration);
    duration = MAX(0, duration);
    self.duration += (NSInteger)(durationDuration * 1000);

    NSMutableDictionary *terminate = [NSMutableDictionary dictionary];
    [terminate setValue:sessionID forKey:kBDAutoTrackEventSessionID];
    [terminate setValue:now forKey:kBDAutoTrackEventTime];
    [terminate setValue:@(duration) forKey:@"duration"];

    long long currentIntervalMS = currentInterval.doubleValue * 1000;
    [terminate setValue:@(currentIntervalMS) forKey:kBDAutoTrackLocalTimeMS];
    [terminate setValue:@(currentInterval.longLongValue) forKey:@"stop_timestamp"];
    [terminate setValue:@(self.launchFrom) forKey:@"launch_from"];
    [terminate setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackAPPVersion];
    
    if (self.isBackground) {
        [terminate setValue:@(self.isBackground) forKey:kBDAutoTrackIsBackground];
    }
    
    BOOL uuidChanged = self.uuidChanged;
    if (uuidChanged)  {
        NSString *previousSessionID = self.previousSessionID;
        if (![sessionID isEqualToString:previousSessionID]) {
            [terminate setValue:previousSessionID forKey:kBDAutoTrackPreviousSessionID];
        }
        [terminate setValue:@(uuidChanged) forKey:kBDAutoTrackUUIDChanged];
    }
    
    [BDAutoTrack trackTerminateEventWithData:terminate];
    
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

- (NSInteger)computeTotalDuration {
    NSInteger duration = self.duration;
    if (self.sessionStart) {
        NSNumber *current = bd_currentInterval();
        double durationDuration = current.doubleValue - self.sessionStartTime;
        duration += (NSInteger)(durationDuration * 1000);
    }
    return duration;
}

@end
