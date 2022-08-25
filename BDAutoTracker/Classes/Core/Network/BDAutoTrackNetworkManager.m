//
//  BDAutoTrackNetworkManager.m
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackNetworkManager.h"
#import "BDTrackerCoreConstants.h"
#import "RangersLog.h"
#import "NSData+VEGZip.h"
#import "BDAutoTrack+Private.h"

static NSDictionary * bd_responseData(NSHTTPURLResponse *response, NSData *data, NSError *error) {
    NSMutableDictionary *rs = [NSMutableDictionary new];
    NSInteger statusCode = response.statusCode;
    /// 小于 100 非法
    if (statusCode > 99) {
        [rs setValue:@(statusCode) forKey:kBDAutoTrackRequestHTTPCode];
    }
    if (error == nil && data != nil) {
        NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&error];
        if ([jsonObj isKindOfClass:[NSDictionary class]] && jsonObj.count > 0) {
            [rs addEntriesFromDictionary:jsonObj];
        }
    }
    
    return rs;
}

static NSMutableURLRequest * bd_requestForURL(NSString *requestURL,
                                              NSString *method,
                                              NSDictionary *headerField) {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [request setHTTPMethod:method];
    
    /* Add HTTP header fields */
    if (headerField.count > 0) {
        [headerField enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }

    return request;
}

/// @abstract 配置URLRequest对象，主要是构建并为其设置payload。
/// @params parameters 数据字典，Payload
/// @param request 需要被设置payload的 NSMutableURLRequest
/// @param needEncrypt 数据加密开关
/// @param needCompress 数据压缩开关
/// @discussion callers: bd_network_syncRequestForURL, bd_network_asyncRequestForURL
void bd_buildBodyData(NSMutableURLRequest *request,
                      NSDictionary *parameters,
                      BOOL needEncrypt,
                      BOOL needCompress,
                      id<BDAutoTrackEncryptionDelegate> encryptionDelegate) {
    if (![parameters isKindOfClass:[NSDictionary class]] || parameters.count < 1) {
        return;
    }

    // 将字典数据转为JSON，并经过可能的压缩和加密后，作为HTTP请求的Payload
    NSData *sendingData;
#ifdef DEBUG
    if (@available(iOS 13.0, *)) {
        sendingData = [NSJSONSerialization dataWithJSONObject:parameters
                                                      options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys | NSJSONWritingWithoutEscapingSlashes
                                                        error:nil];
    } else {
        sendingData = [NSJSONSerialization dataWithJSONObject:parameters
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
    }
#else
    sendingData = [NSJSONSerialization dataWithJSONObject:parameters
                                                  options:0
                                                    error:nil];
#endif
    
    NSData *resultData;
    // 压缩数据，这一步基本不会失败
    NSError *compressionError = nil;
    NSData *compressedData = sendingData;
    if (needCompress) {
        compressedData = [sendingData ve_dataByGZipCompressingWithError:&compressionError];
        if (!compressedData || compressionError) {
            compressedData = sendingData;
        }
    }
    
    // 若block != nil，则代表用户使用了自定义加密逻辑
    if (needEncrypt && needCompress && [encryptionDelegate respondsToSelector:@selector(encryptData:error:)]) {
        NSError *err;
        NSData *_t = [encryptionDelegate encryptData:compressedData error:&err];
        if (!err) {
            resultData = _t;
        }
        [request setValue:nil forHTTPHeaderField:@"Content-Encoding"];
        [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
    } else {
        // 默认加密逻辑
        // 若加密开关打开，则加密数据。这一步可能失败。
        // 若加密成功，则发送先压缩，后加密的数据。
        // 若加密失败，则发送只被压缩过的数据。
        BOOL isPayloadEncrypted = NO;
        if (needEncrypt) {
            NSData * decoratedData = [BDAutoTrack.bdEncryptor encryptData:compressedData error:nil];
            if (decoratedData) {
                resultData = decoratedData;
                [request setValue:nil forHTTPHeaderField:@"Content-Encoding"];
                [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
                isPayloadEncrypted = YES;
            }
        }
        
        if (!isPayloadEncrypted) {
            resultData = compressedData;
        }
    }
    
    [request setHTTPBody:resultData];
}

/// caller: BaseRequest
void bd_network_asyncRequestForURL(NSString *requestURL,
                                   NSString *method,
                                   NSDictionary *headerField,
                                   BOOL needEncrypt,
                                   BOOL needCompress,
                                   NSDictionary *parameters,
                                   BDAutoTrackNetworkFinishBlock callback,
                                   id<BDAutoTrackEncryptionDelegate> encryptionDelegate) {
    NSMutableURLRequest *request = bd_requestForURL(requestURL, method, headerField);
    
    
    bd_buildBodyData(request, parameters, needEncrypt, needCompress, encryptionDelegate);
    BDSyncNetworkFinishBlock completionHandler = ^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        if (callback == nil) {
            return;
        }
        
        NSInteger statusCode = 0;
        if ([taskResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = ((NSHTTPURLResponse *)taskResponse).statusCode;
        }
        
        callback(taskData, taskResponse, taskError);
    };
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

/// @abstract 发起同步请求
/// @return 响应字典
/// @discussion caller: BatchService
NSDictionary * bd_network_syncRequestForURL(NSString *requestURL,
                                            NSString *method,
                                            NSDictionary *headerField,
                                            BOOL needEncrypt,
                                            NSDictionary *parameters,
                                            id<BDAutoTrackEncryptionDelegate> encryptionDelegate) {
    if (![parameters isKindOfClass:[NSDictionary class]] || parameters.count < 1) {
        return nil;
    }

    NSMutableURLRequest *request = bd_requestForURL(requestURL, method, headerField);
    
    bd_buildBodyData(request, parameters, needEncrypt, YES, encryptionDelegate);

    __block NSDictionary *result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BDSyncNetworkFinishBlock completionHandler = ^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        result = bd_responseData((NSHTTPURLResponse *)taskResponse, taskData, taskError);
        dispatch_semaphore_signal(semaphore);
    };
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    return result;
}
    
