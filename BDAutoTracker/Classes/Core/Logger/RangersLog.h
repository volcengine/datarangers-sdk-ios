//
//  RangersLog.h
//  RangersAppLog
//
//  Created by Vincent.Feng on 2022/3/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef RangersLog_h
#define RangersLog_h

typedef enum : int {
    RANGERS_LOG_FLAG_ERROR      =   1 << 0,
    RANGERS_LOG_FLAG_WARNING    =   1 << 2,
    RANGERS_LOG_FLAG_DEBUG      =   1 << 4,
} RANGERS_LOG_FLAG;

typedef NS_ENUM(NSUInteger, RANGERS_LOG_LEVEL) {
    RANGERS_LOG_LEVEL_OFF           =   0,
    RANGERS_LOG_LEVEL_ERROR     =   (RANGERS_LOG_FLAG_ERROR),
    RANGERS_LOG_LEVEL_WARNING   =   (RANGERS_LOG_LEVEL_ERROR | RANGERS_LOG_FLAG_WARNING),
    RANGERS_LOG_LEVEL_DEBUG     =   (RANGERS_LOG_LEVEL_WARNING | RANGERS_LOG_FLAG_DEBUG),
};

#ifdef __OBJC__

#import <Foundation/Foundation.h>

extern void Rangers_LogOBJC(int,
                            NSString *,
                            const char*,
                            int,
                            NSString *,...);

#define RANGERS_LOG_MAYBE(flag,appID,fmt,...) Rangers_LogOBJC(flag, appID, __FILE_NAME__, __LINE__, fmt, ##__VA_ARGS__);

#else

extern void Rangers_LogC(int,
                         const char*,
                         const char*,
                         int,
                         const char*,...);

#define RANGERS_LOG_MAYBE(flag,appID,fmt,...) Rangers_LogC(flag, appID, __FILE_NAME__, __LINE__, fmt, ##__VA_ARGS__);


#endif



#define RL_ERROR(appId,fmt,...)      RANGERS_LOG_MAYBE(RANGERS_LOG_FLAG_ERROR,   appId, fmt,##__VA_ARGS__)
#define RL_WARN(appId,fmt,...)       RANGERS_LOG_MAYBE(RANGERS_LOG_FLAG_WARNING, appId, fmt,##__VA_ARGS__)
#define RL_DEBUG(appId,fmt,...)      RANGERS_LOG_MAYBE(RANGERS_LOG_FLAG_DEBUG,   appId, fmt,##__VA_ARGS__)



#endif /* RangersLog_h */
