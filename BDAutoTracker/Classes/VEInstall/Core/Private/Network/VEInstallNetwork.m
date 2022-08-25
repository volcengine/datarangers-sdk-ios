//
//  VEInstallNetwork.m
//
//  Created by KiBen on 2019/9/18.
//
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

#import "VEInstallNetwork.h"
#import <pthread.h>
#import "VEInstallLog.h"
#import "VEInstallRequestParamUtility.h"

typedef void(^VEInstallNetworkTaskCompletionHandler)(id result, NSInteger statusCode, NSError *error);

@interface VEInstallNetworkTaskDelegate : NSObject <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, copy) VEInstallNetworkTaskCompletionHandler completionHandler;
@end

@implementation VEInstallNetworkTaskDelegate

- (instancetype)init {
    if (self = [super init]) {
        self.receivedData = [NSMutableData data];
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    id result = nil;
    if (self.receivedData) {
        result = self.receivedData.copy;
        self.receivedData = nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:result options:0 error:nil];
    if (json) {
        result = json;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionHandler) {
            self.completionHandler(result, statusCode, error);
        }
    });
}
@end


@interface VEInstallNetwork () <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, copy) NSArray<NSString *> *HTTPMethodsEncodingParametersInURI;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, VEInstallNetworkTaskDelegate *> *taskDelegateCachedDict;
@end

@implementation VEInstallNetwork {
    pthread_mutex_t _mutex;
}

+ (instancetype)network {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        
        pthread_mutex_init(&_mutex, NULL);
        
        self.HTTPMethodsEncodingParametersInURI = @[@"GET", @"HEAD", @"DELETE"];
        self.taskDelegateCachedDict = [NSMutableDictionary dictionary];
        self.delegateQueue = [[NSOperationQueue alloc] init];
        self.delegateQueue.maxConcurrentOperationCount = 1;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.delegateQueue];
    }
    return self;
}

- (void)invalidateAndCancel {
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)finishAndInvalidate {
    [self.session finishTasksAndInvalidate];
    self.session = nil;
}

- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameter success:(nullable void (^)(NSInteger,  id _Nonnull))success failure:(nullable void (^)(NSError *))failure {
    [self POST:URLString parameters:parameter headers:nil success:success failure:failure];
}

- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameter headers:(NSDictionary<NSString *,NSString *> *)headers success:(void (^)(NSInteger,  id _Nonnull))success failure:(void (^)(NSError *))failure {
    NSURLSessionDataTask *dataTask = [self _dataTaskWithHTTPMethod:@"POST" URLString:URLString parameters:parameter headers:headers success:success failure:failure];
    [dataTask resume];
}

- (NSURLSessionDataTask *)_dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(NSDictionary *)parameters
                                         headers:(NSDictionary <NSString *, NSString *> *)headers
                                         success:(void (^)(NSInteger,  id _Nonnull))success
                                          failure:(void (^)(NSError * _Nullable))failure
{
    
    NSError *error = nil;
    NSURLRequest *request = [self _requestWithMethod:method URLString:URLString parameters:parameters headers:headers error:&error];
    if (error) {
        InstallLog(@"创建request失败，error: %@", error);
        return nil;
    }
    
    NSURLSessionDataTask *dataTask = [self _dataTaskWithRequest:request completionHandler:^(id result, NSInteger statusCode, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        }else {
            if (success) {
                success(statusCode, result);
            }
        }
    }];
    return dataTask;
}

- (NSURLRequest *)_requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters headers:(NSDictionary<NSString *, NSString *> *)headers error:(NSError *__autoreleasing *)error {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    request.timeoutInterval = self.timeoutInterval;
    request.allowsCellularAccess = YES;
    request.HTTPMethod = method;
    
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    
    NSString *appID = parameters[@"aid"] ?: @""; // it's not a graceful implementation
    NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[method uppercaseString]]) {
        NSString *query = [VEInstallRequestParamUtility sortedQueryEncodedStringWithParameter:parameters];
        request.URL = [NSURL URLWithString:[request.URL.absoluteString stringByAppendingFormat:request.URL.query ? @"&%@" : @"?%@", query]];
    }else {
        if (!contentType) {
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            contentType = @"application/json";
        }
        NSData *body = nil;
        if ([contentType isEqualToString:@"application/json"]) {
            body = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:error];
        }else {
            body = [[VEInstallRequestParamUtility sortedQueryEncodedStringWithParameter:parameters] dataUsingEncoding:NSUTF8StringEncoding];
        }
        if (self.encryptEnable && self.encryptProvider && [self.encryptProvider respondsToSelector:@selector(encryptData:forAppID:)]) {
            NSData *compressedData = [self.compressProvider compressData:body];
            NSData *encryptedData = [self.encryptProvider encryptData:compressedData forAppID:appID];
            if (encryptedData) {
                body = encryptedData;
                [request setValue:nil forHTTPHeaderField:@"Content-Encoding"];
                [request setValue:@"application/octet-stream;tt-data=a" forHTTPHeaderField:@"Content-Type"];
            }
        }
        request.HTTPBody = body;
    }
    
    return request;
}

- (NSURLSessionDataTask *)_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(nullable VEInstallNetworkTaskCompletionHandler)completionHandler {
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    
    VEInstallNetworkTaskDelegate *delegate = [[VEInstallNetworkTaskDelegate alloc] init];
    delegate.completionHandler = completionHandler;
    [self _setDelegate:delegate forTask:dataTask];
    return dataTask;
}

- (void)_setDelegate:(VEInstallNetworkTaskDelegate *)delegate forTask:(NSURLSessionTask *)task {
    pthread_mutex_lock(&_mutex);
    self.taskDelegateCachedDict[@(task.taskIdentifier)] = delegate;
    pthread_mutex_unlock(&_mutex);
}

- (void)_removeDelegateForTask:(NSURLSessionTask *)task {
    pthread_mutex_lock(&_mutex);
    self.taskDelegateCachedDict[@(task.taskIdentifier)] = nil;
    pthread_mutex_unlock(&_mutex);
}

- (VEInstallNetworkTaskDelegate *)_delegateForTask:(NSURLSessionTask *)task {
    
    pthread_mutex_lock(&_mutex);
    VEInstallNetworkTaskDelegate *delegate = self.taskDelegateCachedDict[@(task.taskIdentifier)];
    pthread_mutex_unlock(&_mutex);
    return delegate;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    VEInstallNetworkTaskDelegate *delegate = [self _delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    VEInstallNetworkTaskDelegate *delegate = [self _delegateForTask:task];
    [delegate URLSession:session task:task didCompleteWithError:error];
    [self _removeDelegateForTask:task];
}

@end
