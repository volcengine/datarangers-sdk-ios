//
//  BDAutoTrackUtility.m
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackUtility.h"
#import <CommonCrypto/CommonCrypto.h>
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

NSString *bd_formatDateString(NSTimeInterval time)
{
    NSString *result = nil;
    @try {
        result = [bd_dateFormatter() stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
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

void bd_run_in_main_thread(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void bd_run_in_main_thread_sync(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

id _Nullable bd_deep_copy(id _Nullable object) {
    @try {
        if (!object) {
            return nil;
        }
        NSData *data;
        if (@available(iOS 11.0, *)) {
            data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:nil];
        } else {
            // Fallback on earlier versions
            data = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
        
        id object;
        if (@available(iOS 11.0, *)) {
            object =  [NSKeyedUnarchiver unarchivedObjectOfClasses:@[[NSDictionary class], [NSArray class]] fromData:data error:nil];
        } else {
            // Fallback on earlier versions
            object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        return object;
    } @catch (NSException *exception) {
        return nil;
    }
}

#pragma des 加解密
NSString * bd_ecs_encode(NSString *inputStr, NSString *key, NSError **error) {
    if (!inputStr || inputStr.length < 1) {
        return inputStr;
    }
    
    NSData *inputData = [inputStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [key dataUsingEncoding:NSASCIIStringEncoding];
    if (keyData.length != kCCKeySize3DES) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"BDAutoTrackECSEncode" code:0 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"key length should be %d", kCCKeySize3DES]
            }];
        }
        return nil;
    }
    
    size_t length;
    NSMutableData *outputData = [NSMutableData dataWithLength:(inputData.length + keyData.length)];
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding, // options
                                     keyData.bytes,
                                     keyData.length,
                                     nil, // iv
                                     inputData.bytes,
                                     inputData.length,
                                     outputData.mutableBytes,
                                     outputData.length,
                                     &length);
    if (status != kCCSuccess) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"BDAutoTrackECSEncode" code:status userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"encode failed, status: %d", status]
            }];
        }
        return nil;
    }
    
    NSString *outputStr;
    [outputData setLength:length];
    outputStr = [outputData base64EncodedStringWithOptions:0];
    
    return outputStr;
}

NSString * bd_ecs_decode(NSString *encodeStr, NSString *key, NSError **error) {
    if (!encodeStr || encodeStr.length < 1) {
        return encodeStr;
    }
    
    NSData *encodeData;
    @try {
        NSData *encodeBase64Data = [encodeStr dataUsingEncoding:NSUTF8StringEncoding];
        encodeData = [[NSData alloc] initWithBase64EncodedData:encodeBase64Data options:0];
    } @catch (NSException *exception) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"BDAutoTrackECSDecode" code:0 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"encodeStr should be base64 string: %@", encodeStr]
            }];
        }
        return nil;
    }
    
    NSData *keyData = [key dataUsingEncoding:NSASCIIStringEncoding];
    if (keyData.length != kCCKeySize3DES) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"BDAutoTrackECSDecode" code:0 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"key length should be %d", kCCKeySize3DES]
            }];
        }
        return nil;
    }
    
    size_t length;
    NSMutableData *outputData = [NSMutableData dataWithLength:(encodeData.length + keyData.length)];
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding, // options
                                     keyData.bytes,
                                     keyData.length,
                                     nil, // iv
                                     encodeData.bytes,
                                     encodeData.length,
                                     outputData.mutableBytes,
                                     outputData.length,
                                     &length);
    if (status != kCCSuccess) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"BDAutoTrackECSEncode" code:status userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"decode failed, status: %d", status]
            }];
        }
        return nil;
    }
    
    NSString *outputStr;
    [outputData setLength:length];
    outputStr = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    return outputStr;
}
