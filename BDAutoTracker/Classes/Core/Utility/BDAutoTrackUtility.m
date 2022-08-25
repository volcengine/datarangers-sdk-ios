//
//  BDAutoTrackUtility.m
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackUtility.h"
#import <CommonCrypto/CommonDigest.h>

NSString *ral_base64_string(NSString *base64) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64
                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSDateFormatter * bd_dateFormatter() {
    static NSDateFormatter* formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        [formatter setLocale:locale];
    });

    return formatter;
}

NSDateFormatter * bd_dayFormatter() {
    static NSDateFormatter* formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        [formatter setLocale:locale];
    });

    return formatter;
}

NSString * bd_UUID() {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

/**
 NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
 等同于
 NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
 [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
 NSDate *date= [formatter dateFromString:@"2001-01-01 00.00.00"];
 NSTimeInterval startTime = CFAbsoluteTimeGetCurrent() + [date timeIntervalSince1970] + [NSTimeZone systemTimeZone].secondsFromGMT;
 不等同于
 CFTimeInterval ss = CACurrentMediaTime();
*/
NSNumber *bd_currentInterval() {
    NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
    return [NSNumber numberWithDouble:nowInterval];
}

NSTimeInterval bd_currentIntervalValue() {
    return [[NSDate date] timeIntervalSince1970];
}

NSNumber * bd_milloSecondsInterval() {
    long long interval = (long long)(bd_currentIntervalValue() * 1000);
    return @(interval);
}

NSString *bd_dateNowString() {
    NSString *result = nil;
    @try {
        result = [bd_dateFormatter() stringFromDate:[NSDate date]];
    } @catch (NSException *exception) {
        result = @"2013-1-15 12:00:00";
    } @finally {

    }

    return result;
}

NSString *bd_dateTodayString() {
    NSString *result = nil;
    @try {
        result = [bd_dayFormatter() stringFromDate:[NSDate date]];
    } @catch (NSException *exception) {
        result = @"";
    } @finally {

    }

    return result;
}

#pragma mark - URL query helpers
NSCharacterSet *bd_customQueryAllowedCharacters(void) {
    static NSCharacterSet *turing_set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        // [set addCharactersInString:@"$-_.+!*'(),"];
        // Why '+' should be percent-encoded? see https://stackoverflow.com/questions/6855624/plus-sign-in-query-string
        [set addCharactersInString:@"-_."];
        turing_set = set;
    });

    return turing_set;
}

NSString *bd_queryFromDictionary(NSDictionary *params) {
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    NSCharacterSet *set = bd_customQueryAllowedCharacters();
    for (id key in params) {
        NSString *queryKey = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:set];
        NSString *queryValue = [[params[key] description] stringByAddingPercentEncodingWithAllowedCharacters:set];

        [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", queryKey, queryValue]];
    }

    return [keyValuePairs componentsJoinedByString:@"&"];
}

NSMutableDictionary *bd_dictionaryFromQuery(NSString *query) {
    if (![query isKindOfClass:[NSString class]] || query.length < 1) {
        return nil;
    }
    
    NSMutableDictionary * result = [NSMutableDictionary new];
    NSArray<NSString *> *items = [query componentsSeparatedByString:@"&"];
    for (NSString *item in items) {
        NSArray *pairComponents = [item componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        [result setValue:value forKey:key];
    }

    return result;
}

#pragma mark - directory paths
static NSString *bd_sandBoxDocumentsPath() {
    static NSString *documentsPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [dirs objectAtIndex:0];
    });
    return documentsPath;
}
static NSString *bd_sandboxLibraryPath() {
    static NSString *libraryPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        libraryPath = [dirs objectAtIndex:0];
    });
    return libraryPath;
}

NSString *bd_trackerLibraryPath() {
    static NSString *path = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *sandboxLibrary = bd_sandboxLibraryPath();
        path = [sandboxLibrary stringByAppendingPathComponent:@"._tob_applog_docu"];  // hidden directory
        NSFileManager *fm = [NSFileManager defaultManager];
        
        /* delete possible folder in document directory */
        {
            NSString *sandboxDocuement = bd_sandBoxDocumentsPath();
            for (NSString *path in @[
                [sandboxDocuement stringByAppendingPathComponent:@"_bdauto_tracker_docu"],
                [sandboxDocuement stringByAppendingPathComponent:@"._bdauto_tracker_docu"]
                                   ]) {
                if ([fm fileExistsAtPath:path isDirectory:NULL]) {
                    [fm removeItemAtPath:path error:nil];
                }
            }
        }
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
            if (!isDir) {
                [fm removeItemAtPath:path error:nil];
                [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
        } else {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
         /// 耗时操作
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL fileURLWithPath:path];
            [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        });
    });

    return path;
}

NSString *bd_trackerLibraryPathForAppID(NSString *appID) {
    NSString *library = bd_trackerLibraryPath();
    NSString *path = [library stringByAppendingPathComponent:appID];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
        if (!isDir) {
            [fm removeItemAtPath:path error:nil];
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } else {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return path;
}

#pragma mark - 序列化
/// 返回提供JSON Dictionary的真深拷贝
/// @param params 可序列化为JSON的Dictionary
NSDictionary *bd_trueDeepCopyOfDictionary(NSDictionary *params) {
#ifdef DEBUG
    struct TDCDebug {
        int method;
        NSUInteger cntKeys;
    } tdcDebug;
    tdcDebug.method = 0;
    tdcDebug.cntKeys = params.count;
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
#endif
    
    if (![params isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    NSDictionary *result;
    NSError *err;
    NSData *paramsData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&err];
    result = [NSJSONSerialization JSONObjectWithData:paramsData options:0 error:&err];
    return result;
}

#pragma mark - JSON helpers
/// 获得JSON对象的String表示。PrettyPrint & UTF-8
/// 如果不是有效的JSON对象则返回nil
/// 目前仅在输出Debug Log时被用到
/// @param param JSON对象
NSString *bd_JSONRepresentation(id param) {
    if (!param || ![NSJSONSerialization isValidJSONObject:param]) {
        return nil;
    }
    NSJSONWritingOptions writingOption;
    if (@available(iOS 13.0, *)) {
        writingOption = NSJSONWritingPrettyPrinted | NSJSONWritingFragmentsAllowed | NSJSONWritingSortedKeys | NSJSONWritingWithoutEscapingSlashes;
    } else {
        // Fallback on earlier versions
        writingOption = NSJSONWritingPrettyPrinted | NSJSONWritingFragmentsAllowed;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:param
                                                   options:writingOption
                                                     error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSDictionary *applog_JSONDictionanryForData(NSData *data) {
    if (data == nil) {
        return nil;
    }
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&error];
    if (error) {
        return nil;
    }
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    }
    
    return nil;
}

id bd_JSONValueForString(NSString *inJSON) {
    NSData *data = [inJSON dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingAllowFragments
                                                  error:&error];
    if (error) {
        return nil;
    }

    return object;
}

/// 计算字符串md5
/// @param cStr C字符串
NSString * bd_calc_md5(const char *cStr) {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        result[0], result[1], result[2], result[3],
        result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11],
        result[12], result[13], result[14], result[15]
    ];
}

BOOL URLMatchPattern(NSString *host, NSString *urlPattern) {
    if ([host isKindOfClass:NSString.class]) {
        urlPattern = [urlPattern stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
        urlPattern = [urlPattern stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
        urlPattern = [NSString stringWithFormat:@"^%@$", urlPattern];
        NSError *error;
        NSRegularExpression *urlPatternRegex = [NSRegularExpression regularExpressionWithPattern:urlPattern options:0 error:&error];
        NSRange range = [urlPatternRegex rangeOfFirstMatchInString:host options:NSMatchingAnchored range:NSMakeRange(0, host.length)];
        return range.location == 0 && range.length == host.length;
    }
    return YES;
}

NSCharacterSet *bd_URLAllowedCharacters(void) {
    static NSMutableCharacterSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet URLHostAllowedCharacterSet]];
    });

    return set;
}
