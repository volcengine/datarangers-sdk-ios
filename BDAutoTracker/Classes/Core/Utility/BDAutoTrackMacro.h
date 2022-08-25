//
//  BDBaseMacro.h
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
#import <Foundation/Foundation.h>

//__FILE__, __LINE__, __FUNCTION__,

#ifndef BDAutoTrackMacro_h
#define BDAutoTrackMacro_h

#import "assert.h"

#define BDAutoTrackWeakSelf __weak typeof(self) wself = self
#define BDAutoTrackStrongSelf __strong typeof(wself) self = wself

#define BDSemaphoreLock(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define BDSemaphoreUnlock(lock) dispatch_semaphore_signal(lock);

#ifndef BDAutoTrackIsEmptyString
#define BDAutoTrackIsEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length < 1)
#endif

#ifndef BDAutoTrackIsEmptyArray
#define BDAutoTrackIsEmptyArray(array) (!array || ![array isKindOfClass:[NSArray class]] || array.count < 1)
#endif

#ifndef BDAutoTrackIsEmptyDictionary
#define BDAutoTrackIsEmptyDictionary(dict) (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count < 1)
#endif

#endif /* BDAutoTrackMacro_h */
