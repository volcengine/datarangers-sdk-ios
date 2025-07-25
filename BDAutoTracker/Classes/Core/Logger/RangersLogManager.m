//
//  RangersLogManager.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersLogManager.h"
#import "RangersConsoleLogger.h"

#import "BDAutoTrack+Private.h"

@implementation RangersLogObject
@end

#define LOG_MAX_QUEUE_SIZE 1000






@interface RangersLogManager () {
    NSMutableArray           *loggers;

    dispatch_queue_t         loggingQueue;
    dispatch_group_t         loggingGroup;

    dispatch_semaphore_t     limitedSemaphore;
    NSLock                   *sycnLocker;
}

@end

@implementation RangersLogManager

NSMutableSet *gLoggerClasses;

+ (void)initialize
{
    if (self == [RangersLogManager class]) {
        gLoggerClasses = [NSMutableSet new];
    }
}

+ (void)registerLogger:(Class)cls
{
    @synchronized (self) {
        [gLoggerClasses addObject:cls];
    }
}

+ (NSArray<Class> *)registerLoggerClasses
{
    NSArray *cls;
    @synchronized (self) {
        cls = [gLoggerClasses allObjects];
    }
    return cls;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        loggers = [NSMutableArray new];
        NSString *queueName = [NSString stringWithFormat:@"volcengine.logger.%p",self];
        loggingQueue = dispatch_queue_create(queueName.UTF8String, NULL);
        loggingGroup = dispatch_group_create();
        limitedSemaphore = dispatch_semaphore_create(LOG_MAX_QUEUE_SIZE);
        self.logLevel = VETLOG_LEVEL_WARN;
        sycnLocker = [NSLock new];
    }
    return self;
}


- (void)addLogger:(id<RangersLogger>)logger
{
    dispatch_async(loggingQueue, ^{
        
        if ([self->loggers containsObject:logger]) {
            return;
        }
        [self->loggers addObject:logger];
        logger.tracker = self.tracker;
        if ([logger respondsToSelector:@selector(didAddLogger)]) {
            dispatch_async(logger.queue, ^{
                [logger didAddLogger];
            });
        }
        
    });
}

- (void)removeLogger:(id<RangersLogger>)logger
{
    dispatch_async(loggingQueue, ^{
        if (![self->loggers containsObject:logger]) {
            return;
        }
        if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
            dispatch_async(logger.queue, ^{
                [logger willRemoveLogger];
            });
        }
        [self->loggers removeObject:logger];
    });
}

- (NSArray *)loggers
{
    return [self->loggers copy];
}

- (void)removeAllLoggers
{
    dispatch_async(loggingQueue, ^{
        for (id<RangersLogger> logger in self->loggers)
        {
            if ([logger respondsToSelector:@selector(willRemoveLogger)])
            {
                dispatch_async(logger.queue, ^{
                    [logger willRemoveLogger];
                });
            }
        }
        [self->loggers removeAllObjects];
    });
}

- (void)log:(RangersLogObject *)obj
{
    dispatch_semaphore_wait(limitedSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_block_t block = ^{
        for (id<RangersLogger> logger in self->loggers) {
            dispatch_group_async(self->loggingGroup, logger.queue, ^{
                [logger log:obj];
            });
            dispatch_group_wait(self->loggingGroup, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_signal(self->limitedSemaphore);
        }
    };
    
#if DEBUG
    dispatch_sync(loggingQueue, block);
#else
    dispatch_async(loggingQueue, block);
#endif
    
}




@end


#pragma mark - Log

static void _logInternal(int flag,
                            NSArray<BDAutoTrack *> *trackers,
                            const char *module,
                            const char *message)
{
    @try {
        [trackers enumerateObjectsUsingBlock:^(BDAutoTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RangersLogObject *logObj = [RangersLogObject new];
            logObj.flag = flag;
            logObj.timestamp = [[NSDate new] timeIntervalSince1970];
            if (strlen(module)) {
                logObj.module = [[NSString alloc] initWithUTF8String:module];
            }
            if (strlen(message)) {
                logObj.message = [[NSString alloc] initWithUTF8String:message];
            }
            logObj.appId = obj.appID;
            [obj.logger log:logObj];
        }];
    }@catch(...){}
    
    
}


void Rangers_LogOBJC(int flag,
                     BDAutoTrack* tracker,
                     NSString *module,
                     NSString *format,...)
{
    NSArray *trackers;
    if ([tracker isKindOfClass:BDAutoTrack.class] && tracker.config.showDebugLog) {
        trackers = @[tracker];
    } else if (tracker == nil){
        NSArray *allTrackers = [BDAutoTrack allTrackers];
        NSMutableArray *tmp = [NSMutableArray array];
        [allTrackers enumerateObjectsUsingBlock:^(BDAutoTrack*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.config.showDebugLog) {
                [tmp addObject:obj];
            }
        }];
        trackers = [tmp copy];
    }
    if (trackers.count == 0) {
        return;
    }
    NSString *message = nil;
    @try {
        va_list args;
        va_start(args, format);
        message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
    } @catch (NSException *exception) {
        message = format;
    }
    
    _logInternal(flag, trackers, module.UTF8String, [message UTF8String]);
    
}


