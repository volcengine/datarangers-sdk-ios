//
//  BDAutoTrackRegisterRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRegisterRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackReachability.h"

#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackUtility.h"
#import "RangersLog.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackNetworkManager.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrack+Private.h"


@interface BDAutoTrackRegisterRequest ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) BOOL hasObserveNetworkChange;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *requestArray;

@end

@implementation BDAutoTrackRegisterRequest

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLRegister;
        self.semaphore = dispatch_semaphore_create(1);
        self.hasObserveNetworkChange = NO;
        bd_registerReloadParameters(appID);
        
        self.requestArray = [NSMutableArray array];
        self.serialQueue = dispatch_queue_create([@"com.applog.register_request" UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }

    return self;
}

#pragma mark - Request

- (void)startRequestWithRetry:(NSInteger)retry {
    
    BDAutoTrackWeakSelf;
    dispatch_block_t block = ^{
        BDAutoTrackStrongSelf;
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
        RL_INFO(tracker, @"DeviceRegister", @"Device register request. (retry:%d)",retry);
        [super startRequestWithRetry:retry];
    };
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        if ([self addNetworkObserver]) {
            [self.requestArray addObject:block];
            return;
        }
        
        if (self.isRequesting) {
            [self.requestArray addObject:block];
            return;
        }
        
        block();
    });
}

- (void)triggerRequestArray {
    BDAutoTrackWeakSelf;
    dispatch_async(self.serialQueue, ^{
        BDAutoTrackStrongSelf;
        
        if (self.isRequesting) {
            return;
        }
        
        if (self.requestArray.count < 1) {
            return;
        }
        
        dispatch_block_t block = [self.requestArray firstObject];
        [self.requestArray removeObject:block];
        if (block) {
            block();
        }
    });
}

- (void)notifyResponse {
    [self triggerRequestArray];
}

- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = NO;
    BDSemaphoreLock(self.semaphore);
    BDAutoTrackRegisterService *registerService = bd_registerServiceForAppID(self.appID);
    
    NSString * requestUUID = [[request objectForKey:kBDAutoTrackHeader] objectForKey:kBDAutoTrackEventUserID];
    if (![requestUUID isKindOfClass:[NSString class]]) {
        requestUUID = nil;
    }
    NSString *currentUUID =  self.registeringUserUniqueID ?:@"";
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    if (([requestUUID length] == 0 && self.registeringUserUniqueID.length == 0)
        || [currentUUID isEqualToString:requestUUID] ) {
        success = [registerService updateParametersWithResponse:responseDict urlResponse:urlResponse];
        
        if (success) {
            RL_INFO(tracker, @"DeviceRegister", @"Device register success.");
            dispatch_block_t callback = self.successCallback;
            if (callback != nil) {
                callback();
                self.successCallback = nil;
            }
        } else {
            RL_ERROR(tracker, @"DeviceRegister", @"Device register handle response failure.");
        }
        
        
    } else {
        RL_WARN(tracker, @"DeviceRegister", @"register reponse UUID not match");
    }
    
    if (success) {
        [tracker.localConfig updateServerTime:responseDict];
        [registerService postRegisterSuccessNotificationWithDataSource:BDAutoTrackNotificationDataSourceServer];
    }
    BDSemaphoreUnlock(self.semaphore);
    
 
    return success;
}

- (void)handleFailureResponseWithRetry:(NSInteger)retry reason:(NSString *)reason {
    [self postRegisterFailureNotificationWithRetry:retry reason:reason];

    [super handleFailureResponseWithRetry:retry reason:reason];
}

#pragma mark - notification

- (void)onConnectionChanged {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BDAutoTrackReachabilityDidChangeNotification
                                                  object:nil];
    self.hasObserveNetworkChange = NO;
    
    [self triggerRequestArray];
}

- (BOOL)addNetworkObserver {
    if (![[BDAutoTrackEnviroment sharedEnviroment] isNetworkConnected]) {
        if (!self.hasObserveNetworkChange) {
            self.hasObserveNetworkChange = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onConnectionChanged)
                                                         name:BDAutoTrackReachabilityDidChangeNotification
                                                       object:nil];
        }

        return YES;
    }

    return NO;
}

- (NSMutableDictionary *)requestHeaderParameters {
    NSMutableDictionary *header = [super requestHeaderParameters];
    bd_registerAddParameters(header, self.appID);
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    
    if(tracker.config.newUserMode) {
        //if not existst bd_did / deviceId
        NSString *bddid = [header objectForKey:kBDAutoTrackBDDid];
        NSString *deviceId = [header objectForKey:@"device_id"];
        if (bddid.length == 0 && deviceId.length == 0) {
            [header setValue:@(1) forKey:@"new_user_mode"];
        }
    }
    
#if TARGET_OS_OSX
    
#endif
    
    return header;
}


- (void)postRegisterFailureNotificationWithRetry:(NSInteger)retry reason:(NSString *)reason {
    NSDictionary *userInfo = @{
        @"message": @"register request failure",
        @"reason": reason,
        @"remainingRetry": @(retry)
    };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationRegisterFailure
                                                        object:nil
                                                      userInfo:userInfo];
}

- (id)syncRegister:(NSDictionary *)additions
{
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    NSString *appID = self.appID;
    if (tracker.localConfig == nil) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to SETTINGS IS NULL. (%@)",NSStringFromClass([self class]));
        return nil;
    }
    NSString *requestURL = self.requestURL;
    if (requestURL.length < 1 || [requestURL containsString:@"(null)"]) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to URL IS NULL",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"requestURL is nil"];
        return nil;
    }
    NSMutableDictionary *parameters = [[self requestParameters] mutableCopy];
    NSMutableDictionary *header = [[parameters objectForKey:kBDAutoTrackHeader] mutableCopy];
    [header removeObjectForKey:kBDAutoTrackSSID];
    [header addEntriesFromDictionary:additions];
    [header bdheader_keyFormat];
    [parameters setValue:header forKey:kBDAutoTrackHeader];
    if (![NSJSONSerialization isValidJSONObject:parameters]) {
        RL_ERROR(tracker, @"DeviceRegister", @"sync terminate due to INVALD JSON. (%@)",NSStringFromClass([self class]));
        [self handleFailureResponseWithRetry:0 reason:@"invalid request parameters"];
        return nil;
    }
    
    NSDictionary *requestBody = bd_filterSensitiveParameters(parameters, self.appID);
    bd_handleCommonParamters(requestBody, tracker, self.requestType);
    NSDictionary *result = bd_network_syncRequestForURL(requestURL,
                                                        self.method,
                                                        bd_headerField(appID),
                                                        requestBody,
                                                        tracker.networkManager);
    
    return result;
    
    
}

@end
