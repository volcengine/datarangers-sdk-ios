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
    VETLOG_FLAG_ERROR      =   1 << 0,
    VETLOG_FLAG_WARN       =   1 << 1,
    VETLOG_FLAG_INFO       =   1 << 2,
    VETLOG_FLAG_DEBUG      =   1 << 3,
} VETLOG_FLAG;

typedef NS_ENUM(NSUInteger, VETLOG_LEVEL) {
    VETLOG_LEVEL_OFF       =   0,
    VETLOG_LEVEL_ERROR     =   (VETLOG_FLAG_ERROR),
    VETLOG_LEVEL_WARN      =   (VETLOG_LEVEL_ERROR | VETLOG_FLAG_WARN),
    VETLOG_LEVEL_INFO      =   (VETLOG_LEVEL_WARN | VETLOG_FLAG_INFO),
    VETLOG_LEVEL_DEBUG     =   (VETLOG_LEVEL_INFO | VETLOG_FLAG_DEBUG),
};


#ifdef __OBJC__

#import <Foundation/Foundation.h>

void Rangers_LogOBJC(int flag,
                     id tracker,
                     NSString *module,
                     NSString *format,...);

#define RANGERS_LOG_MAYBE(flag,tracker,module, fmt,...) Rangers_LogOBJC(flag, tracker, module, fmt, ##__VA_ARGS__);

#endif



#define RL_ERROR(tracker,module,fmt,...)      RANGERS_LOG_MAYBE(VETLOG_FLAG_ERROR,   tracker,module, fmt,##__VA_ARGS__)
#define RL_WARN(tracker,module,fmt,...)       RANGERS_LOG_MAYBE(VETLOG_FLAG_WARN,    tracker,module, fmt,##__VA_ARGS__)
#define RL_INFO(tracker,module,fmt,...)       RANGERS_LOG_MAYBE(VETLOG_FLAG_INFO,    tracker,module, fmt,##__VA_ARGS__)
#define RL_DEBUG(tracker,module,fmt,...)      RANGERS_LOG_MAYBE(VETLOG_FLAG_DEBUG,   tracker,module, fmt,##__VA_ARGS__)



#endif 
