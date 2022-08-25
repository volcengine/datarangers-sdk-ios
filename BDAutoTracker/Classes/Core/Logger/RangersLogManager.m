//
//  RangersLogManager.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersLogManager.h"
#import "RangersConsoleLogger.h"

@implementation RangersLogObject
@end

#define LOG_MAX_QUEUE_SIZE 1000

static NSMutableArray           *gLoggers;
static RANGERS_LOG_LEVEL        gLogLevel;

static dispatch_queue_t         gLoggingQueue;
static dispatch_group_t         gLoggingGroup;

static dispatch_semaphore_t     gLimitedSemaphore;

static NSMutableSet             *gLogModules;

static NSLock                   *sycnLocker;

@implementation RangersLogManager

+ (void)initialize
{
    if (self == [RangersLogManager class]) {
        
        gLoggers = [NSMutableArray new];
        gLoggingQueue = dispatch_queue_create("rangers.logger.global", NULL);
        gLoggingGroup = dispatch_group_create();
        gLimitedSemaphore = dispatch_semaphore_create(LOG_MAX_QUEUE_SIZE);
        gLogLevel = RANGERS_LOG_LEVEL_ERROR;
        [RangersLogManager addLogger:[RangersConsoleLogger new]];
        gLogModules = [NSMutableSet set];
        sycnLocker = [NSLock new];
    }
}

+ (void)setLogLevel:(RANGERS_LOG_LEVEL)logLevel
{
    gLogLevel = logLevel;
}

+ (RANGERS_LOG_LEVEL)logLevel
{
    return gLogLevel;
}

+ (void)enableModule:(NSString *)appId
{
    if ([appId length] == 0) {
        return;
    }
    [sycnLocker lock];
    [gLogModules addObject:appId];
    [sycnLocker unlock];
}

+ (BOOL)enabledForAppId:(NSString *)appId
{
    if ([appId length] == 0) {
        return NO;
    }
    BOOL enabled = NO;
    [sycnLocker lock];
    enabled = [gLogModules containsObject:appId];
    [sycnLocker unlock];
    return enabled;
}



+ (void)addLogger:(id<RangersLogger>)logger
{
    dispatch_async(gLoggingQueue, ^{
        
        if ([gLoggers containsObject:logger]) {
            return;
        }
        [gLoggers addObject:logger];
        if ([logger respondsToSelector:@selector(didAddLogger)]) {
            dispatch_async(logger.queue, ^{
                [logger didAddLogger];
            });
        }
        
    });
}

+ (void)removeLogger:(id<RangersLogger>)logger
{
    dispatch_async(gLoggingQueue, ^{
        if (![gLoggers containsObject:logger]) {
            return;
        }
        if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
            dispatch_async(logger.queue, ^{
                [logger willRemoveLogger];
            });
        }
        [gLoggers removeObject:logger];
    });
}

+ (void)removeAllLoggers
{
    dispatch_async(gLoggingQueue, ^{
        for (id<RangersLogger> logger in gLoggers)
        {
            if ([logger respondsToSelector:@selector(willRemoveLogger)])
            {
                dispatch_async(logger.queue, ^{
                    [logger willRemoveLogger];
                });
            }
        }
        [gLoggers removeAllObjects];
    });
}

+ (void)log:(RangersLogObject *)obj
{
    dispatch_semaphore_wait(gLimitedSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_block_t block = ^{
        for (id<RangersLogger> logger in gLoggers) {
            dispatch_group_async(gLoggingGroup, logger.queue, ^{
                [logger log:obj];
            });
            dispatch_group_wait(gLoggingGroup, DISPATCH_TIME_FOREVER);
            dispatch_semaphore_signal(gLimitedSemaphore);
        }
    };
    
#if DEBUG
    dispatch_sync(gLoggingQueue, block);
#else
    dispatch_async(gLoggingQueue, block);
#endif
    
}




@end


#pragma mark - Log

static void _logInternal(int flag,
                            NSString* appId,
                            const char* file,
                            int line,
                            const char *message)
{
    RangersLogObject *logObj = [RangersLogObject new];
    logObj.flag = flag;
    logObj.line = line;
    logObj.timestamp = [[NSDate new] timeIntervalSince1970];
    logObj.module = appId;
    if (strlen(file)) {
        logObj.file = [[NSString alloc] initWithUTF8String:file];
    }
    if (strlen(message)) {
        logObj.message = [[NSString alloc] initWithUTF8String:message];
    }
    [RangersLogManager log:logObj];
}


void Rangers_LogOBJC(int flag,
                     NSString* appId,
                     const char* file,
                     int line,
                     NSString *format,...)
{
    
    if (appId.length > 0 && ![RangersLogManager enabledForAppId:appId]) {
        return;
    }
    
    NSString *message = @"";
    @try {
        va_list args;
        va_start(args, format);
        message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
    } @catch (NSException *exception) {
        message = format;
    }
    
    _logInternal(flag, appId, file, line, [message UTF8String]);
}

void Rangers_LogC(int flag,
                  const char* appId,
                  const char* file,
                  int line,
                  const char* format, ...) {
    
//    if ( (RangersLogManager.logLevel & flag) == 0) {
//        return;
//    }
    NSString *appIdString = @"";
    if (strlen(appId)) {
        appIdString =  [[NSString alloc] initWithUTF8String:appId];
    }
    if (![RangersLogManager enabledForAppId:appIdString]) {
        return;
    }

    int n, size = 1024;
    char *p;
    va_list args;
    if ( (p = (char *) malloc(size*sizeof(char))) == NULL)
        return;
    
    if (format != NULL) {
        while (1)
        {
            
            va_start(args, format);
            n = vsnprintf (p, size, format, args);
            va_end(args);
            
            if (n > -1 && n < size)
                break;
            
            size *= 2; /* 两倍原来大小的空间 */
            if ((p = (char *)realloc(p, size*sizeof(char))) == NULL)
                return;
        }
        _logInternal(flag, appIdString, file, line, p);
    }
}



