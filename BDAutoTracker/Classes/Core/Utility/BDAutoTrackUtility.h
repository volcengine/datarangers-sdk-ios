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
/// UUID 每次调用产生新的，如果需要保存唯一，得自行处理
FOUNDATION_EXTERN NSString * bd_UUID(void);
FOUNDATION_EXTERN NSNumber * bd_currentInterval(void);
FOUNDATION_EXTERN NSTimeInterval bd_currentIntervalValue(void);
FOUNDATION_EXTERN NSNumber * bd_milloSecondsInterval(void);
FOUNDATION_EXTERN NSString *bd_dateNowString(void);
FOUNDATION_EXTERN NSString *bd_dateTodayString(void);

/* process URL query */
NSCharacterSet *bd_customQueryAllowedCharacters(void);
FOUNDATION_EXTERN NSString *bd_queryFromDictionary(NSDictionary *params);
FOUNDATION_EXTERN NSMutableDictionary *_Nullable bd_dictionaryFromQuery(NSString *_Nullable query);

/* directory paths */
FOUNDATION_EXTERN NSString *bd_trackerLibraryPath(void);
FOUNDATION_EXTERN NSString *bd_trackerLibraryPathForAppID(NSString *appID);

/// 其实是返回可序列化对象，不是说深拷贝
FOUNDATION_EXTERN NSDictionary *bd_trueDeepCopyOfDictionary(NSDictionary *_Nullable params);

/* JSON helpers */
FOUNDATION_EXTERN NSString *_Nullable bd_JSONRepresentation(id _Nullable param);
FOUNDATION_EXTERN id _Nullable bd_JSONValueForString(NSString *_Nullable inJSON);
FOUNDATION_EXTERN NSDictionary *_Nullable  applog_JSONDictionanryForData(NSData *data);

/* hash 计算 */
FOUNDATION_EXTERN NSString * bd_calc_md5(const char *cStr);

FOUNDATION_EXTERN BOOL URLMatchPattern(NSString *host, NSString *urlPattern);

FOUNDATION_EXTERN NSCharacterSet *bd_URLAllowedCharacters(void);

NS_ASSUME_NONNULL_END
