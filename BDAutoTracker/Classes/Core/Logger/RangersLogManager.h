//
//  RangersLogManager.h
//  RangersAppLog
//
//  Created by Vincent.Feng on 2022/3/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "RangersLog.h"

NS_ASSUME_NONNULL_BEGIN


@class BDAutoTrack;
@interface RangersLogObject : NSObject

@property (nonatomic) VETLOG_FLAG  flag;

@property (nonatomic) NSTimeInterval    timestamp;

@property (nonatomic, copy) NSString *  appId;

@property (nonatomic, copy) NSString *  module;

@property (nonatomic, copy) NSString *  file;

@property (nonatomic) NSUInteger        line;

@property (nonatomic, copy) NSString *  message;

@end


@protocol RangersLogger <NSObject>

@property (nonatomic, weak) BDAutoTrack *tracker;

@required

- (void)log:(RangersLogObject *)log;

- (dispatch_queue_t)queue;

@optional

- (void)flush;

- (void)didAddLogger;

- (void)willRemoveLogger;

@end


@interface RangersLogManager : NSObject

@property (nonatomic, weak) BDAutoTrack *tracker;

@property (nonatomic, assign) VETLOG_LEVEL logLevel;

- (void)log:(RangersLogObject *)log;

- (void)addLogger:(id<RangersLogger>)logger;

- (void)removeLogger:(id<RangersLogger>)logger;

- (void)removeAllLoggers;

- (NSArray<RangersLogger> *)loggers;

+ (void)registerLogger:(Class)cls;

+ (NSArray<Class> *)registerLoggerClasses;


@end

NS_ASSUME_NONNULL_END
