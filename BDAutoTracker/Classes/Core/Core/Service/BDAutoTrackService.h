//
//  BDAutoTrackService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackBaseTable;

@protocol BDAutoTrackService <NSObject>

@property (nonatomic, copy, readonly, nullable) NSString *appID;
@property (nonatomic, copy, readonly, nullable) NSString *serviceName;

- (instancetype)initWithAppID:(NSString *)appID;
- (BOOL)serviceAvailable;
- (void)registerService;
- (void)unregisterService;

@end

FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameTracker;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameSettings;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameRegister;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameDatabase;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameLogger;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameRemote;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameABTest;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameBatch;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameLog;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameSimulator;
FOUNDATION_EXTERN NSString * const BDAutoTrackServiceNameFilter;

@protocol BDAutoTrackCanSendEvent
@required
- (void)sendEvent:(NSDictionary *)event key:(NSString *)key;
@end

/// 遵循此协议的类
/// 1. Log子库的RealTimeService
/// 2. ET/Log的ETService
@protocol BDAutoTrackLogService <BDAutoTrackService, BDAutoTrackCanSendEvent>

@end

@protocol BDAutoTrackFilterService <BDAutoTrackService>
- (nullable NSDictionary *)filterEvent:(NSDictionary *)event;
- (void)updateBlockList:(NSDictionary *)eventList save:(BOOL)save;
@end

@interface BDAutoTrackService : NSObject<BDAutoTrackService>

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy, nullable) NSString *serviceName;

- (instancetype)initWithAppID:(NSString *)appID;
- (BOOL)serviceAvailable;
- (void)registerService;
- (void)unregisterService;

@end


NS_ASSUME_NONNULL_END
