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
#import "NSData+VECompression.h"
#import "NSData+VECryptor.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackURLHostProvider.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackUtility.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDAutoTrackLocalConfigService.h"

static NSDictionary * bd_responseData(NSHTTPURLResponse *response, NSData *data, NSError *error) {
    NSMutableDictionary *rs = [NSMutableDictionary new];
    NSInteger statusCode = response.statusCode;
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
    
    if (headerField.count > 0) {
        [headerField enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }

    return request;
}


void bd_buildBodyData(NSMutableURLRequest *request,
                      NSDictionary *parameters,
                      BDAutoTrackNetworkManager *networkManager) {
    if (![parameters isKindOfClass:[NSDictionary class]] || parameters.count < 1) {
        return;
    }

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
    
    [request setHTTPBody:sendingData];
    [networkManager.encryptor encryptRequest:request tracker:networkManager.tracker];
}

void bd_buildBodyData_without_encryptor(NSMutableURLRequest *request,
                      NSDictionary *parameters,
                      BDAutoTrackNetworkManager *networkManager) {
    if (![parameters isKindOfClass:[NSDictionary class]] || parameters.count < 1) {
        return;
    }

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
    
    [request setHTTPBody:sendingData];
}

void bd_network_asyncRequestForURL(NSString *requestURL,
                                   NSString *method,
                                   NSTimeInterval timeout,
                                   NSDictionary *headerField,
                                   NSDictionary *parameters,
                                   BDAutoTrackNetworkManager *networkManager,
                                   BDAutoTrackNetworkFinishBlock callback) {
    
    NSMutableURLRequest *request = bd_requestForURL(requestURL, method, headerField);
    
    
    bd_buildBodyData(request, parameters, networkManager);
    NSString *requestId = [NSUUID UUID].UUIDString;
    if (networkManager.tracker.networkBlock) {
        networkManager.tracker.networkBlock(requestId, requestURL, method, headerField, parameters, nil, nil, 0);
    }
    BDSyncNetworkFinishBlock completionHandler = ^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        if (callback == nil) {
            return;
        }
        
        NSInteger statusCode = 0;
        if ([taskResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = ((NSHTTPURLResponse *)taskResponse).statusCode;
        }
        if (networkManager.tracker.networkBlock) {
            NSDictionary *result = [networkManager.encryptor parseResponse: taskData];
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)taskResponse;
            networkManager.tracker.networkBlock(requestId, requestURL, method, headerField, parameters, response.allHeaderFields, result, statusCode);
        }
        callback(taskData, taskResponse, taskError);
    };
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

NSDictionary * bd_network_syncRequestForURL(NSString *requestURL,
                                            NSString *method,
                                            NSDictionary *headerField,
                                            NSDictionary *parameters,
                                            BDAutoTrackNetworkManager *networkManager) {
    if (![parameters isKindOfClass:[NSDictionary class]] || parameters.count < 1) {
        return nil;
    }

    NSMutableURLRequest *request = bd_requestForURL(requestURL, method, headerField);
    
    bd_buildBodyData(request, parameters, networkManager);
    NSString *requestId = [NSUUID UUID].UUIDString;
    if (networkManager.tracker.networkBlock) {
        networkManager.tracker.networkBlock(requestId, requestURL, method, headerField, parameters, nil, nil, 0);
    }
    __block NSDictionary *result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BDSyncNetworkFinishBlock completionHandler = ^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        result = bd_responseData((NSHTTPURLResponse *)taskResponse, taskData, taskError);
        if (networkManager.tracker.networkBlock) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)taskResponse;
            networkManager.tracker.networkBlock(requestId, requestURL, method, headerField, parameters, response.allHeaderFields, result, response.statusCode);
        }
        dispatch_semaphore_signal(semaphore);
    };
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    return result;
}


@interface BDAutoTrackNetworkEncryptor()

@property (nonatomic, nullable) id<BDAutoTrackEncryptionDelegate> defaultDelegate;
@property (nonatomic, nullable) id<BDAutoTrackEncryptionDelegate> sm2Delegate;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *iv;

@end

@implementation BDAutoTrackNetworkEncryptor

- (instancetype)init {
    self = [super init];
    if (self) {
        self.encryptionType = BDAutoTrackEncryptionTypeDefault;
        self.key = [[NSUUID UUID].UUIDString substringToIndex:32];
        self.iv = [[NSUUID UUID].UUIDString substringToIndex:16];
    }
    return self;
}

- (void)encryptRequest:(NSMutableURLRequest *)request tracker:(BDAutoTrack *)tracker {
    NSData *body = request.HTTPBody;
    
    NSError *error;
    body = [self encrypt:body error:&error];
    if (error) {
        RL_WARN(tracker, @"Network", @"compression failure. (%@:%@)",request.URL.absoluteString, error.localizedDescription ?: @"");
        return;
    }

    if (!body) {
        return;
    }
    
    [self appendHeader:request];
    [request setHTTPBody:body];
}

- (NSMutableDictionary *)encryptParameters:(NSMutableDictionary *)parameters allowedKeys:(NSArray *)allowedKeys {
    if (!self.encryption) {
        return parameters;
    }
    
    NSMutableDictionary *allowedParameters = [NSMutableDictionary new];
    for (NSString *key in parameters) {
        if([allowedKeys containsObject:key]) {
            [allowedParameters setValue:parameters[key] forKey:key];
        }
    }
    
    NSString *query = bd_queryFromDictionary(parameters);
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSData *encryptedData = [self encrypt:queryData error:&error];
    if (encryptedData) {
        queryData = encryptedData;
    }
    
    NSString *base64QueryStr = [queryData base64EncodedStringWithOptions:0];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    [allowedParameters setValue:base64QueryStr forKey:kBDAutoTrackTTInfo];
    return allowedParameters;
}

- (NSString *)encryptUrl:(NSString *)url allowedKeys:(NSArray *)allowedKeys {
    if (!self.encryption) {
        return url;
    }
    
    NSURLComponents *urlComp = [NSURLComponents componentsWithString:url];
    NSString *query = [NSURL URLWithString:url].query;
    NSData *queryData = [query dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSData *encryptedData = [self encrypt:queryData error:&error];
    if (encryptedData) {
        queryData = encryptedData;
    }
    
    NSString *base64QueryStr = [queryData base64EncodedStringWithOptions:0];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64QueryStr = [base64QueryStr stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    
    
    NSMutableArray<NSURLQueryItem *> *newQueryItems = [NSMutableArray array];
    [newQueryItems addObject:[NSURLQueryItem queryItemWithName:kBDAutoTrackTTInfo value:base64QueryStr]];
    for (NSURLQueryItem *item in urlComp.queryItems) {
        if([allowedKeys containsObject:item.name]) {
            [newQueryItems addObject:item];
        }
    }
    urlComp.queryItems = newQueryItems;
    
    return urlComp.string;
}

- (NSData *)encrypt:(NSData *)data error:(NSError * __autoreleasing *)error {
    if (!self.encryption) {
        return nil;
    }
    
    NSData *encryptedData = [data vecompress_gzip:error];
    if (*error) {
        return nil;
    }
    
    id<BDAutoTrackEncryptionDelegate> delegate = self.delegate;
    if (!delegate || ![delegate respondsToSelector:@selector(encryptData:error:)]) {
        return nil;
    }
    
    encryptedData = [self.delegate encryptData:encryptedData error:error];
    if (*error) {
        return nil;
    }
    
    return encryptedData;
}

- (void)appendHeader:(NSMutableURLRequest *) request {
    if (self.encryptionType == BDAutoTrackEncryptionTypeDefault) {
        id<BDAutoTrackEncryptionDelegate> delegate = self.delegate;
        if (!delegate || ![delegate respondsToSelector:@selector(encryptData:error:)]) {
            return;
        }
        [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
        return;
    }
}

- (NSString *)contentTypeHeader {
    if (self.encryption) {
        id<BDAutoTrackEncryptionDelegate> delegate = self.delegate;
        if (!delegate || ![delegate respondsToSelector:@selector(encryptData:error:)]) {
            return @"application/json; encoding=utf-8";
        }
        if (self.encryptionType == BDAutoTrackEncryptionTypeDefault) {
            return @"application/octet-stream;tt-data=a";
        }
    }
    return @"application/json; encoding=utf-8";
}

- (id<BDAutoTrackEncryptionDelegate>)delegate {
    if (self.customDelegate) {
        return self.customDelegate;
    }
    if (self.encryptionType == BDAutoTrackEncryptionTypeDefault) {
        if (!self.defaultDelegate) {
            self.defaultDelegate = [self loadDefaultDelegate];
        }
        return self.defaultDelegate;
    }
    return nil;
}

- (id<BDAutoTrackEncryptionDelegate>)loadDefaultDelegate
{
    static id<BDAutoTrackEncryptionDelegate> delegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [self createDelegate:@"BDAutoTrackEncryptor"];
    });
    return delegate;
}

- (id<BDAutoTrackEncryptionDelegate>)createDelegate:(NSString *)className {
    Class encryptorCls = NSClassFromString(className);
    if (encryptorCls) {
        return [[encryptorCls alloc] init];
    }
    return nil;
}

- (NSDictionary *)parseResponse:(NSData *)data {
    NSDictionary *result = nil;

    if (result == nil) {
        result = applog_JSONDictionanryForData(data);
    }
    return result;
}

@end



@interface BDAutoTrackNetworkManager ()<NSURLSessionDelegate> {
    NSMapTable *taskById;
}

@end

@implementation BDAutoTrackNetworkManager {
    
    NSOperationQueue *delegateQueue;
    NSURLSessionConfiguration *configuration;
    NSURLSession *session;
}


+ (instancetype)managerWithTracker:(BDAutoTrack *)tracker;
{
    BDAutoTrackNetworkManager *network = [BDAutoTrackNetworkManager new];
    network.tracker = tracker;
    return network;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        taskById = [NSMapTable strongToWeakObjectsMapTable];
        configuration =  [NSURLSessionConfiguration defaultSessionConfiguration];
        delegateQueue = [NSOperationQueue new];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:delegateQueue];
    }
    return self;
}

- (NSError *)internalErrorWithMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:@"VETrackerNetworkError" code:0 userInfo:@{
        NSLocalizedDescriptionKey:message ?:@""
    }];
    return error;
}

- (NSMutableDictionary *)commonParameter
{
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    bd_addBodyNetworkParams(header, self.tracker.appID);
    bd_addSettingParameters(header, self.tracker.appID);
    bd_registeredAddParameters(header, self.tracker.appID);
    bd_addABVersions(header, self.tracker.appID);
#if TARGET_OS_IOS
    NSDictionary *utmData = [self.tracker.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    NSDictionary *tracerData = [self.tracker.alinkActivityContinuation tracerData];
    [header setValue:tracerData forKey:kBDAutoTrackTracerData];
#endif
    [header bdheader_keyFormat];
    return header;
}

- (NSDictionary *)_mergedBody:(NSDictionary *)body
{
    NSMutableDictionary *parameter = [body mutableCopy];
    
    NSMutableDictionary *defaultHeader = [self commonParameter];
    NSMutableDictionary *inputHeader = [[body objectForKey:kBDAutoTrackHeader] mutableCopy];
    if (inputHeader.count > 0) {
        [inputHeader bdheader_keyFormat];
        [defaultHeader addEntriesFromDictionary:inputHeader];
    }
    [parameter setValue:defaultHeader forKey:kBDAutoTrackHeader];
    
    [parameter setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    return parameter;
}

- (void)sync:(BDAutoTrackRequestURLType)type
      method:(NSString *)method
      header:(nullable NSDictionary *)header
   parameter:(nullable NSDictionary *)parameter
      config:(BDAutoTrackNetworkRequestConfig *)config
  completion:(BOOL (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
{
    
    RL_DEBUG(self.tracker, @"Network", @"[%d] request start %@...", type, config ? [NSString stringWithFormat:@"[retry:%d][timeout:%d]", (int)config.retry, (int)config.timeout] :@"");
    NSError *err;
    
    if (type != BDAutoTrackRequestURLRegister && !bd_registerServiceAvailableForAppID(self.tracker.appID) && config.requireDeviceRegister) {
        err = [self internalErrorWithMessage:@"NOT Register yet"];
        RL_WARN(self.tracker,@"Network",@"[%d] request terminate due to %@",type,err.localizedDescription);
        completionHandler(nil, nil, err);
        return;
    }
    
    NSString *urlstring = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:type appID:self.tracker.appID];
    urlstring = bd_appendQueryToURL(urlstring, @"aid", self.tracker.appID);
    NSURL *url = [NSURL URLWithString:urlstring];
    if (!url) {
        err = [self internalErrorWithMessage:@"Invalid URL"];
        RL_ERROR(self.tracker, @"Network", @"[%d] request terminate due to %@", type, err.localizedDescription);
        completionHandler(nil, nil, err);
        return;
    }
    
    NSMutableDictionary *defaultHTTPHeaderFileds = bd_headerField(self.tracker.appID);
    if (header.count > 0) {
        [defaultHTTPHeaderFileds addEntriesFromDictionary:header];
    }
    NSMutableURLRequest *request = bd_requestForURL(urlstring, method, defaultHTTPHeaderFileds);
    
    
    
    NSDictionary *body = [parameter copy];
    //merge header
    if ([@"POST" isEqualToString:method]) {
        body = [self _mergedBody:body];
        if (![NSJSONSerialization isValidJSONObject:body]) {
            err = [self internalErrorWithMessage:@"Invalid parameter"];
            RL_ERROR(self.tracker, @"Network", @"[%d] request terminate due to %@", type, err.localizedDescription);
            completionHandler(nil, nil, err);
            return;
        }
    }
    
    bd_handleCommonParamters(body, self.tracker, type);
    NSString *requestId = [NSUUID UUID].UUIDString;
    if (self.tracker.networkBlock) {
        self.tracker.networkBlock(requestId, urlstring, method, defaultHTTPHeaderFileds, body, nil, nil, 0);
    }
    [self encryptRequest:request parameter:body];
    
    BOOL (^handler)(NSData *, NSURLResponse *, NSError *) = [completionHandler copy];
    
    __block NSInteger remainTimes = 0;
    
    if (config) {
        remainTimes = (int)config.retry;
        request.timeoutInterval = config.timeout;
    }
    
    while (YES) {
        RL_DEBUG(self.tracker, @"Network", @"[%d] request try [remains:%d]",type, remainTimes);
        CFAbsoluteTime requestTime = CFAbsoluteTimeGetCurrent();
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BDSyncNetworkFinishBlock block = ^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
            
            CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - requestTime;
            BOOL success = handler(taskData, taskResponse, taskError);
            if (success) {
                RL_INFO(self.tracker, @"Network", @"[%d] request done",type);
                remainTimes = 0;
            } else {
                if (taskError) {
                    RL_ERROR(self.tracker, @"Network", @"[%d] request error due to %@", type, taskError.localizedDescription);
                } else {
                    RL_ERROR(self.tracker, @"Network", @"[%d] request error due to Invalid Response", type);
                }
            }
            if (self.tracker.networkBlock) {
                NSDictionary *result = [self.encryptor parseResponse: taskData];
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)taskResponse;
                self.tracker.networkBlock(requestId, urlstring, method, defaultHTTPHeaderFileds, body, response.allHeaderFields, result, response.statusCode);
            }
            remainTimes --;
            dispatch_semaphore_signal(semaphore);
            
        };
        NSURLSessionTask *task =  [session dataTaskWithRequest:request completionHandler:block];
        [task resume];
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, request.timeoutInterval * 2 * NSEC_PER_SEC));
        if (remainTimes < 0) {
            break;
        }
    }
    
}



#pragma mark - Post
- (void)encryptRequest:(NSMutableURLRequest *)request
             parameter:(NSDictionary *)parameter
{
    //POST
    parameter = bd_filterSensitiveParameters(parameter, self.tracker.appID);
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"POST"]) {
        NSData *body = [NSJSONSerialization dataWithJSONObject:parameter
                                                           options:0
                                                             error:nil];
        [request setHTTPBody:body];
        [self.encryptor encryptRequest:request tracker:self.tracker];
    }
    
    
}

@end
    

@implementation BDAutoTrackNetworkRequestConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeout = 10.0f;
        self.requireDeviceRegister = YES;
    }
    return self;
}
@end
