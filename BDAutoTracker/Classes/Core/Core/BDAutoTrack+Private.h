//
//  BDAutoTrack+Private.h
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/6/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"
#import "BDCommonDefine.h"
#import "BDAutoTrackDataCenter.h"
#import "BDAutoTrackProfileReporter.h"
#import "BDAutoTrackALinkActivityContinuation.h"
#import "BDAutoTrackEncryptionDelegate.h"
#import "RangersLogManager.h"
#import "BDAutoTrackEventGenerator.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrack (Private)

@property (class) id<BDAutoTrackEncryptionDelegate> bdEncryptor;

@property (nonatomic, readonly) RangersLogManager *logger;

@property (nonatomic, readonly) BDAutoTrackEventGenerator *eventGenerator;

@property (nonatomic, readonly) BDAutoTrackNetworkManager *networkManager;

@property (nonatomic, readonly) BDAutoTrackRemoteSettingService *remoteConfig;

@property (nonatomic, readonly) BDAutoTrackLocalConfigService *localConfig;

@property (nonatomic, readonly) BDAutoTrackABConfig *abTester;

@property (nonatomic, strong) BDAutoTrackIdentifier *identifier;


@property (nonatomic, readonly) BDAutoTrackConfig *config;
@property (nonatomic, readonly) NSLock *syncLocker;
@property (nonatomic, strong) NSMutableSet *ignoredPageClasses;
@property (nonatomic, strong) NSMutableSet *ignoredClickViewClasses;

@property (nonatomic, strong) BDAutoTrackDataCenter *dataCenter;
@property (nonatomic, assign) BOOL showDebugLog;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, readonly, strong) BDAutoTrackALinkActivityContinuation *alinkActivityContinuation API_UNAVAILABLE(macos);

@property (nonatomic, copy) BDAutoTrackEventHandler eventHandler;
@property (nonatomic, assign) NSUInteger eventHandlerTypes;

@property (nonatomic, copy) void(^eventBlock)(BDAutoTrackEventStatus eventStatus, BDAutoTrackEventAllType eventType, NSString *eventName, NSDictionary<NSString *, id> *properties);

@property (nonatomic, copy) void(^networkBlock)(NSString *requestId, NSString *requestURL, NSString *method, NSDictionary *requestHeader, NSDictionary *requestBody, NSDictionary * _Nullable responseHeader, NSDictionary * _Nullable responseBody, NSInteger statusCode);;

@property (nonatomic, strong) BDAutoTrackProfileReporter *profileReporter;

@property (nonatomic, weak) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

+ (NSArray<BDAutoTrack *> *)allTrackers;

+ (void)trackUIEventWithData:(NSDictionary *)data;

+ (void)trackLaunchEventWithData:(NSMutableDictionary *)data;

+ (void)trackTerminateEventWithData:(NSMutableDictionary *)data;

+ (void)trackPlaySessionEventWithData:(NSDictionary *)data;

- (void)flushWithTimeInterval:(NSInteger)flushTimeInterval;

- (void)setAppTouchPoint:(NSString *)appTouchPoint;

- (BOOL)registerAvalible;

@end

NS_ASSUME_NONNULL_END
