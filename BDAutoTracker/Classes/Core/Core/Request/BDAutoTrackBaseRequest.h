//
//  BDAutoTrackBaseRequest.h
//  RangersAppLog
//
//  Created by bob on 2020/6/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackEncryptionDelegate.h"
#import "BDCommonEnumDefine.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackBaseRequest : NSObject

@property (nonatomic, copy) NSString *method;
@property (nonatomic, assign) BOOL encrypt;
@property (nonatomic, assign) BOOL compress;
@property (nonatomic, copy, nullable) NSString *requestURL;
@property (nonatomic, assign) BDAutoTrackRequestURLType requestType;

@property (nonatomic, copy, nullable)  dispatch_block_t successCallback;
@property (nonatomic, copy, nullable)  dispatch_block_t failureCallback;

@property (nonatomic, copy, readonly) NSString *appID;

/// 用于给Post body和激活请求的tt_info query加密
@property (nonatomic, weak, readonly) id<BDAutoTrackEncryptionDelegate> encryptionDelegate;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)startRequestWithRetry:(NSInteger)retry;

- (nullable NSMutableDictionary *)requestParameters;
- (nullable NSMutableDictionary *)requestHeaderParameters;

- (BOOL)handleResponse:(NSDictionary *)response
           urlResponse:(NSURLResponse *)urlResponse
               request:(NSDictionary *)request
                 retry:(NSInteger)retry;

- (BOOL)handleResponse:(NSDictionary *)response
           urlResponse:(NSURLResponse *)urlResponse
               request:(NSDictionary *)request;

- (nullable NSDictionary *)responseFromData:(nullable NSData *)data
                                      error:(nullable NSError *)error;


- (void)handleSuccessResponse;
- (void)handleFailureResponseWithRetry:(NSInteger)retry reason:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
