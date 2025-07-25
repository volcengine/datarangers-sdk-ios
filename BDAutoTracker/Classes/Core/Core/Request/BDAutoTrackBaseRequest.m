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
#import "NSMutableDictionary+BDAutoTrackParameter.h"

@interface BDAutoTrackBaseRequest ()

@property (nonatomic, copy) NSString *appID;

@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackBaseRequest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.method = @"POST";
        self.appID = appID;
        self.timeout = 30.0f;
        self.requestURL = nil;
        self.associatedTrack = [BDAutoTrack trackWithAppID:appID];
        self.isRequesting = NO;
    }

    return self;
}

#pragma mark - 请求: 发起请求
- (void)startRequestWithRetry:(NSInteger)retry {
    if (retry < 0) {
        return;
    }
    RL_DEBUG(self.associatedTrack,@"Network", @"request call [retry:%d]. (%@)", retry,NSStringFromClass([self class]));
    NSString *appID = self.appID;
    if (self.associatedTrack.localConfig == nil) {
        RL_ERROR(self.associatedTrack,@"Network", @"terminate due to SETTINGS IS NULL. (%@)",NSStringFromClass([self class]));
        return;
    }
    
    NSString *requestURL = self.requestURL;
    if (requestURL.length < 1) {
        RL_ERROR(self.associatedTrack,@"Network", @"terminate due to URL IS NULL",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"requestURL is nil"];
        return;
    }
    
    NSDictionary *result = [self requestParameters];
    if (![NSJSONSerialization isValidJSONObject:result]) {
        RL_ERROR(self.associatedTrack,@"Network", @"terminate due to INVALD JSON. (%@)",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"invalid request parameters"];
        return;
    }
    
    
    CFAbsoluteTime requestTime = CFAbsoluteTimeGetCurrent();
    BDAutoTrackWeakSelf;
    BDAutoTrackNetworkFinishBlock callback = ^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        BDAutoTrackStrongSelf;
        self.isRequesting = NO;
        
        NSDictionary *response = [self responseFromData:data error:nil];
        NSDictionary *request  = [result copy];
        BOOL success = [self handleResponse:response urlResponse:urlResponse request:request retry:retry];
        
        
        CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - requestTime;
        NSURL *url = [NSURL URLWithString:requestURL];
        
        [self notifyResponse];
    };
    
    RL_DEBUG(self.associatedTrack,@"Network", @"request start. (%@)", requestURL);
    NSDictionary *requestBody = bd_filterSensitiveParameters(result, self.appID);
    bd_handleCommonParamters(requestBody, self.associatedTrack, self.requestType);
    bd_network_asyncRequestForURL(requestURL,
                                  self.method,
                                  self.timeout ?: 30.0f,
                                  bd_headerField(appID),
                                  requestBody,
                                  self.associatedTrack.networkManager,
                                  callback);
    self.isRequesting = YES;
}

#pragma mark - 请求: 拼装HTTP body
- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *result = bd_requestPostHeaderParameters(self.appID);
    bd_addABVersions(result, self.appID);

    return result;
}

- (NSMutableDictionary *)requestParameters {
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    NSMutableDictionary *header = [self requestHeaderParameters];
    
   
#if TARGET_OS_IOS
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    NSDictionary *tracerData = [track.alinkActivityContinuation tracerData];
    [header setValue:tracerData forKey:kBDAutoTrackTracerData];
#endif
    [header bdheader_keyFormat];
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
        RL_DEBUG(self.associatedTrack,@"Network", @"request failure .[retry:%d](%@)", retry, NSStringFromClass([self class]));
       [self handleFailureResponseWithRetry:retry reason:@"handleResponse failed"];
    }
    
    return success;
}

- (NSDictionary *)responseFromData:(NSData *)data error:(NSError *)error {
    if (error == nil && data != nil) {
        return applog_JSONDictionanryForData(data);
    }
    RL_WARN(self.associatedTrack,@"Network", @"request failure due to INVALID RESPONSE. (%@)", NSStringFromClass([self class]));
    return nil;
}

- (void)handleFailureResponseWithRetry:(NSInteger)retry reason:(NSString *)reason {
    
    if (retry > 0) {
        BDAutoTrackWeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDAutoTrackStrongSelf;
            [self startRequestWithRetry:retry - 1];
        });
    }
    else {
        RL_ERROR(self.associatedTrack,@"Network", @"request failure. (%@)", NSStringFromClass([self class]));
        dispatch_block_t failCallback = self.failureCallback;
        if (failCallback) {
            dispatch_async(dispatch_get_main_queue(), failCallback);
        }
    }
}

- (void)handleSuccessResponse {
    RL_INFO(self.associatedTrack,@"Network", @"request success. (%@)", NSStringFromClass([self class]));
    dispatch_block_t successCallback = self.successCallback;
    if (successCallback) {
        dispatch_async(dispatch_get_main_queue(), successCallback);
    }
}

- (void)notifyResponse {}

@end
