//
//  BDAutoTrackUtility.h
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#import "NSURLRequest+RALDebug.h"
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *ral_base64_string(NSString *base64);
FOUNDATION_EXTERN NSDateFormatter * bd_dateFormatter(void);
FOUNDATION_EXTERN NSDateFormatter * bd_dayFormatter(void);
FOUNDATION_EXTERN NSString * bd_UUID(void);
FOUNDATION_EXTERN NSNumber * bd_currentInterval(void);
FOUNDATION_EXTERN NSTimeInterval bd_currentIntervalValue(void);
FOUNDATION_EXTERN NSNumber * bd_milloSecondsInterval(void);
FOUNDATION_EXTERN NSString *bd_dateNowString(void);
FOUNDATION_EXTERN NSString *bd_dateTodayString(void);
FOUNDATION_EXTERN NSString *bd_formatDateString(NSTimeInterval time);

NSCharacterSet *bd_customQueryAllowedCharacters(void);
FOUNDATION_EXTERN NSString *bd_queryFromDictionary(NSDictionary *params);
FOUNDATION_EXTERN NSMutableDictionary *_Nullable bd_dictionaryFromQuery(NSString *_Nullable query);

FOUNDATION_EXTERN NSString *bd_trackerLibraryPath(void);
FOUNDATION_EXTERN NSString *bd_trackerLibraryPathForAppID(NSString *appID);

FOUNDATION_EXTERN NSDictionary *bd_trueDeepCopyOfDictionary(NSDictionary *_Nullable params);

FOUNDATION_EXTERN NSString *_Nullable bd_JSONRepresentation(id _Nullable param);
FOUNDATION_EXTERN id _Nullable bd_JSONValueForString(NSString *_Nullable inJSON);
FOUNDATION_EXTERN NSDictionary *_Nullable  applog_JSONDictionanryForData(NSData *data);

FOUNDATION_EXTERN NSString * bd_calc_md5(const char *cStr);

FOUNDATION_EXTERN BOOL URLMatchPattern(NSString *host, NSString *urlPattern);

FOUNDATION_EXTERN NSCharacterSet *bd_URLAllowedCharacters(void);

FOUNDATION_EXTERN void bd_run_in_main_thread(dispatch_block_t);

FOUNDATION_EXTERN void bd_run_in_main_thread_sync(dispatch_block_t);

FOUNDATION_EXTERN id _Nullable bd_deep_copy(id _Nullable);

FOUNDATION_EXTERN NSString * bd_ecs_encode(NSString *inputStr, NSString *key, NSError **error);
FOUNDATION_EXTERN NSString * bd_ecs_decode(NSString *encodeStr, NSString *key, NSError **error);

NS_ASSUME_NONNULL_END
