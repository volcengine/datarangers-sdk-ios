//
//  BDAutoTrackBaseRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/6/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBaseRequest.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackUtility.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrack+Private.h"
#import "RangersLog.h"

@interface BDAutoTrackBaseRequest ()

@property (nonatomic, copy) NSString *appID;

/// appID关联的track实例
@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackBaseRequest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.method = @"POST";
        self.encrypt = bd_settingsServiceForAppID(appID).logNeedEncrypt;
        self.compress = YES;
        self.appID = appID;
        self.requestURL = nil;
        self.associatedTrack = [BDAutoTrack trackWithAppID:appID];
    }

    return self;
}

#pragma mark - 请求: 发起请求
/// 向服务器发送异步请求
/// @param retry 附加重试次数。若为0，则不重试；若为大于0的值，则在本次请求后，还可以最多重试retry次。
- (void)startRequestWithRetry:(NSInteger)retry {
    if (retry < 0) {
        return;
    }
    RL_DEBUG(self.appID, @"[NETWORK] request call [retry:%d]. (%@)", retry,NSStringFromClass([self class]));
    // 获取settings服务。若获取不到则直接失败
    NSString *appID = self.appID;
    if (bd_settingsServiceForAppID(appID) == nil) {
        RL_ERROR(appID, @"[NETWORK] terminate due to SETTINGS IS NULL. (%@)",NSStringFromClass([self class]));
        return;
    }
    
    // 获取请求地址。若获取不到则直接失败
    NSString *requestURL = self.requestURL;
    if (requestURL.length < 1) {
        RL_ERROR(self.appID, @"[NETWORK] terminate due to URL IS NULL",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"requestURL is nil"];
        [[[BDAutoTrack trackWithAppID:self.appID] monitorAgent] trackUrl:nil type:self.requestType response:nil interval:0 success:NO error:nil];
        return;
    }
    
    NSDictionary *result = [self requestParameters];
    if (![NSJSONSerialization isValidJSONObject:result]) {
        RL_ERROR(appID, @"[NETWORK] terminate due to INVALD JSON. (%@)",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"invalid request parameters"];
        [[[BDAutoTrack trackWithAppID:self.appID] monitorAgent] trackUrl:[NSURL URLWithString:requestURL] type:self.requestType response:nil interval:0 success:NO error:nil];
        return;
    }
    
    
    CFAbsoluteTime requestTime = CFAbsoluteTimeGetCurrent();
    BDAutoTrackWeakSelf;
    BDAutoTrackNetworkFinishBlock callback = ^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        BDAutoTrackStrongSelf;
        NSDictionary *response = [self responseFromData:data error:nil];
        NSDictionary *request  = [result copy];
        BOOL success = [self handleResponse:response urlResponse:urlResponse request:request retry:retry];
        
        
        CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - requestTime;
        NSURL *url = [NSURL URLWithString:requestURL];
        [[[BDAutoTrack trackWithAppID:self.appID] monitorAgent] trackUrl:url type:self.requestType response:(NSHTTPURLResponse *)urlResponse interval:interval success:success error:error];
    };
    
    // 获取请求所携带的数据(作为HTTP Body)。若数据不符合JSON格式，则直接失败
    
    RL_DEBUG(self.appID, @"[NETWORK] request start. (%@)", requestURL);
    bd_network_asyncRequestForURL(requestURL,
                                  self.method,
                                  bd_headerField(self.compress, appID),
                                  self.encrypt,
                                  self.compress,
                                  result,
                                  callback,
                                  self.encryptionDelegate);
}

#pragma mark - 请求: 拼装HTTP body
/// HTTP body中的header字段。
- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *result = bd_requestPostHeaderParameters(self.appID);
    bd_addABVersions(result, self.appID);

    return result;
}

/// HTTP body
- (NSMutableDictionary *)requestParameters {
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    NSMutableDictionary *header = [self requestHeaderParameters];
    
   
#if TARGET_OS_IOS
    /* alink utm */
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    /* alink tracer_data */
    NSDictionary *tracerData = [track.alinkActivityContinuation tracerData];
    [header setValue:tracerData forKey:kBDAutoTrackTracerData];
#endif
    [result setValue:header forKey:kBDAutoTrackHeader];
    
    return result;
}

#pragma mark - 处理响应
- (BOOL)handleResponse:(NSDictionary *)response
           urlResponse:(NSURLResponse *)urlResponse
               request:(NSDictionary *)request{
    return YES;
}

- (BOOL)handleResponse:(NSDictionary *)response
           urlResponse:(NSURLResponse *)urlResponse
               request:(NSDictionary *)request
                 retry:(NSInteger)retry {
    BOOL success = [self handleResponse:response urlResponse:urlResponse request:request];
    if (success) {
        [self handleSuccessResponse];
    } else {
        RL_DEBUG(self.appID, @"[NETWORK] request failure .[retry:%d](%@)", retry, NSStringFromClass([self class]));
       [self handleFailureResponseWithRetry:retry reason:@"handleResponse failed"];
    }
    
    return success;
}

- (NSDictionary *)responseFromData:(NSData *)data error:(NSError *)error {
    if (error == nil && data != nil) {
        return applog_JSONDictionanryForData(data);
    }
    RL_WARN(self.appID, @"[NETWORK] request failure due to INVALID RESPONSE. (%@)", NSStringFromClass([self class]));
    return nil;
}

/// 处理失败响应。如果请求失败但还有重试机会，则不算重新发起请求。若已耗尽重试机会，则执行失败回调。
/// @param retry 剩余重试机会次数
- (void)handleFailureResponseWithRetry:(NSInteger)retry reason:(NSString *)reason {
    
    if (retry > 0) {
        BDAutoTrackWeakSelf;
        // 收到失败响应后，若还有重试机会，则在3秒后重新发送请求
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDAutoTrackStrongSelf;
            [self startRequestWithRetry:retry - 1];
        });
    }
    else {
        RL_ERROR(self.appID, @"[NETWORK] request failure. (%@)", NSStringFromClass([self class]));
        dispatch_block_t failCallback = self.failureCallback;
        if (failCallback) {
            dispatch_async(dispatch_get_main_queue(), failCallback);
        }
    }
}

- (void)handleSuccessResponse {
    RL_ERROR(self.appID, @"[NETWORK] request success. (%@)", NSStringFromClass([self class]));
    dispatch_block_t successCallback = self.successCallback;
    if (successCallback) {
        dispatch_async(dispatch_get_main_queue(), successCallback);
    }
}

#pragma mark computed property
- (id<BDAutoTrackEncryptionDelegate>)encryptionDelegate {
    return self.associatedTrack.encryptionDelegate;
}

@end
