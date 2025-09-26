//
//  BDAutoTrackBatchService.m
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBatchService.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackBatchData.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDAutoTrackReachability.h"
#import "BDAutoTrackUtility.h"

#import "BDAuoTrackEventBlock.h"
#import "BDAutoTrackBatchSchedule.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDAutoTrackBatchPacker.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackEventUntils.h"

#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackRegisterService.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackNetworkRequest.h"


#import "BDAutoTrack.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackSettingsRequest.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackURLHostProvider.h"

#import "RangersLog.h"
#import "RangersRouter.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDAutoTrackerDefines.h"

static const NSUInteger        kEventMaxCountPerRequest    = 200;

@interface BDAutoTrackBatchService () {
    BOOL realtimeBatchInLine;
}

@property (nonatomic, strong) dispatch_queue_t sendingQueue;
@property (nonatomic, assign) BDAutoTrackTriggerSource fromType;
@property (nonatomic, strong) BDAutoTrackBatchSchedule *schedule;
@property (nonatomic, strong) BDAutoTrackBatchTimer *batchTimer;
@property (nonatomic, strong) BDAuoTrackEventBlock *eventBlcok;

@property (nonatomic, assign) CFTimeInterval requestStartTime;

@property (nonatomic, assign) long long lastManuallyTime;

@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@property (nonatomic, assign) int reportCount;

@end

@implementation BDAutoTrackBatchService

#pragma mark - public

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameBatch;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.log_%@",appID];
        self.sendingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        self.fromType = BDAutoTrackTriggerSourceInitApp;
        self.schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:appID];
        self.batchTimer = [[BDAutoTrackBatchTimer alloc] initWithAppID:appID];
        self.batchTimer.request = self;
        self.eventBlcok = [[BDAuoTrackEventBlock alloc] initWithAppID:appID];
        self.lastManuallyTime = 0;
        self.associatedTrack = [BDAutoTrack trackWithAppID:appID];
        self.reportCount = kEventMaxCountPerRequest;
        RL_INFO(self.associatedTrack,@"Uploader", @"Module enabled");
    }
    
    return self;
}


+ (BOOL)syncBatch:(BDAutoTrack *)tracker withEvents:(NSArray *)events
{
    NSString *appId = tracker.appID;
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLLog appID:appId];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appId);
    
    //pack
    BDAutoTrackBatchData *batch = [BDAutoTrackBatchData new];
    batch.sendingTrackData = @{@"event_v3": events};
    [batch filterData];
    
    NSMutableDictionary *batchBody = [self postBody:tracker withBatchData:batch];
    
    NSMutableDictionary* header = [batchBody objectForKey:kBDAutoTrackHeader];
    id ssid = [header objectForKey:kBDAutoTrackSSID];
    if (ssid == nil || ssid == [NSNull null]) {
        [header setValue:[NSUUID UUID].UUIDString forKey:kBDAutoTrackSSID];
    } else if ([ssid isKindOfClass:NSString.class]) {
        NSString *ssid_str = (NSString *) ssid;
        if (ssid_str.length < 1) {
            [header setValue:[NSUUID UUID].UUIDString forKey:kBDAutoTrackSSID];
        }
    }
    
    NSDictionary *requestBody = bd_filterSensitiveParameters(batchBody, tracker.appID);
    bd_handleCommonParamters(requestBody, tracker, BDAutoTrackRequestURLLog);
    NSDictionary *responseDict = bd_network_syncRequestForURL(requestURL,
                                                              @"POST",
                                                              bd_headerField(appId),
                                                              requestBody,
                                                              tracker.networkManager);
    
    BOOL success = bd_isValidResponse(responseDict) && bd_isResponseMessageSuccess(responseDict);
    return success;
    
}


 




- (void)sendTrackDataFrom:(NSInteger)from {
    [self sendTrackDataFrom:from flushTimeInterval:10];  // Flush
}

- (void)sendTrackDataFrom:(NSInteger)from flushTimeInterval:(NSInteger)flushTimeInterval {
    RL_DEBUG(self.associatedTrack,@"Uploader",@"Trigger upload [source: %d]", from);
    if (!bd_registerServiceAvailableForAppID(self.appID)) {
        [self.batchTimer endBackgroundTask];
        RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to NOT Register successful.");
        return;
    }
    
    if (from == BDAutoTrackTriggerSourceManually) {
        long long now = CACurrentMediaTime();
        if (now - self.lastManuallyTime < flushTimeInterval) {
            RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to MANUALLY TOO OFFEN.");
            return;
        }
        self.lastManuallyTime = now;
    }
    
    dispatch_async(self.sendingQueue,^{
        @autoreleasepool {
            [self sendTrackDataInternalFrom:from
                                    options:nil
                                    handler:nil];
        }
    });
}

- (void)realtimeEventBatch
{
    if (self->realtimeBatchInLine) {
        return;
    }
    self->realtimeBatchInLine = YES;
    dispatch_async(self.sendingQueue,^{
        self->realtimeBatchInLine = NO;
        [self sendTrackDataInternalFrom:BDAutoTrackTriggerSourceRealtime
                                options:@{@"priority":@(BDAutoTrackEventPriorityRealtime)}
                                handler:nil];
        
    });
}

#pragma mark - private

- (void)sendTrackDataInternalFrom:(NSInteger)from
                          options:(nullable NSDictionary *)options
                          handler:(void(^)(void))handler {
    
    if (!self.associatedTrack.eventReportingEnabled && from != BDAutoTrackTriggerSourceManually) {
        RL_DEBUG(self.associatedTrack, @"Uploader", @"terminate due to EVENT REPORTING DISABLED.");
        if (handler) {
            handler();
        }
        return;
    }
    
    if (from != BDAutoTrackTriggerSourceRealtime) {
        [self.associatedTrack.eventGenerator restoreBulkCounter];
    }
    self.fromType = from;
    NSMutableDictionary *queryOptions;
    if (options) {
        queryOptions = [options mutableCopy];
    } else {
        queryOptions = [NSMutableDictionary dictionary];
    }
    [queryOptions setObject:[NSNumber numberWithInt:self.reportCount] forKey:@"queryCount"];
    RL_DEBUG(self.associatedTrack, @"Uploader", @"sendTrackDataInternalFrom queryOptions: %@", queryOptions);
    NSDictionary<NSString *, NSArray *> *allTracks = [bd_databaseServiceForAppID(self.appID) allTracksForBatchReport:queryOptions];
    
    NSArray *tasks = bd_batchPackAllTracksSplitByUUID(allTracks, kEventMaxCountPerRequest);
    if (tasks.count == 0) {
        RL_DEBUG(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
    }
    __block NSUInteger currentEventCount = 0;
    __block BOOL tasksAllSuccess = YES;
    [tasks enumerateObjectsUsingBlock:^(BDAutoTrackBatchData*  _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        
        task.source = from;
        
        currentEventCount += task.maxEventCount;
        
        if (task.maxEventCount < 1)  {
            RL_DEBUG(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
            return;
        }
        
        if ([task.ssID length] == 0) {
            NSString *ssid = [RangersRouter sync:[RangersRouting routing:@"ssid"
                                                                    base:self.appID
                                                              parameters: @{
                kBDAutoTrackEventUserID: task.userUniqueID?:[NSNull null],
                kBDAutoTrackEventUserIDType: task.userUniqueIDType?:[NSNull null]
            }]];
            if ([ssid length] > 0) {
                task.ssID = ssid;
            } else {
                tasksAllSuccess = NO;
                RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to FAILURE FIX SSID.");
                return;
            }
            
        }
        
        [task checkSendData:task.ssID];
        
        task.autoTrackEnabled = bd_remoteSettingsForAppID(self.appID).autoTrackEnabled;
        [task filterData];
        if (task.realSentData.count < 1) {
            tasksAllSuccess = NO;
            [self.batchTimer endBackgroundTask];
            RL_INFO(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
            return;
        }
        
        if (from != BDAutoTrackTriggerSourceRealtime) {
            if (![self.schedule actionInSchedule]) {
                if (from != BDAutoTrackTriggerSourceEnterBackground) {
                    tasksAllSuccess = NO;
                    [self.batchTimer endBackgroundTask];
                    RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to FLOW CONTROL.");
                    return;
                }
            }
        }

        BOOL success = [self sendTrackDataInternalFirstTime:YES task:task];
        if (success) {
            RL_DEBUG(self.associatedTrack,@"Uploader",@"request successful .");
        } else {
            tasksAllSuccess = NO;
            RL_DEBUG(self.associatedTrack,@"Uploader",@"request failure .");
        }
    }];
    
    if (handler != nil) {
        handler();
    }
    if (tasksAllSuccess
        && currentEventCount >= kEventMaxCountPerRequest) {
        [self sendTrackDataFrom:from];
    } else {
        if (from == BDAutoTrackTriggerSourceEnterBackground && tasksAllSuccess) {
            [bd_databaseServiceForAppID(self.appID) vacuumDatabase];
        }
        
        [self.batchTimer endBackgroundTask];
    }
}

#pragma mark request
- (NSMutableDictionary *)requestParametersWithData:(NSDictionary *)data {
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSMutableDictionary *header = bd_requestPostHeaderParameters(self.appID);
    bd_addABVersions(header, self.appID);
    
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    
#if TARGET_OS_IOS
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    [header setValue:[track.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    [result setValue:header forKey:kBDAutoTrackHeader];
    [result setValue:[track.localConfig serverTime] forKey:kBDAutoTrackTimeSync];
    [result setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];

    if ([data isKindOfClass:[NSDictionary class]] && data.count > 0) {
        [result addEntriesFromDictionary:data];
    }
    
    return result;
}

- (BOOL)sendTrackDataInternalFirstTime:(BOOL)first task:(BDAutoTrackBatchData *)task {
    
    
    self.requestStartTime = CFAbsoluteTimeGetCurrent();
    NSString *appID = self.appID;
    
    BDAutoTrackRequestURLType type = first ? BDAutoTrackRequestURLLog : BDAutoTrackRequestURLLogBackup;
    
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:type appID:appID];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appID);
    RL_DEBUG(self.associatedTrack,@"Uploader",@"request start use primay(%d) (count:%d). (%@)",first, task.maxEventCount, requestURL);
    task.sendTime = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *requestBody = [self postHandlerParameters:task];
    requestBody = bd_filterSensitiveParameters(requestBody, self.associatedTrack.appID);
    bd_handleCommonParamters(requestBody, self.associatedTrack, type);
    NSDictionary *responseDict = bd_network_syncRequestForURL(requestURL,
                                                              @"POST",
                                                              bd_headerField(appID),
                                                              requestBody,
                                                              self.associatedTrack.networkManager);

    return [self handleBatchSendCallback:responseDict firstTime:first task:task];
}

- (NSMutableDictionary *)postHandlerParameters:(BDAutoTrackBatchData *)task
{
    NSDictionary *data = task.realSentData;
    NSMutableDictionary *body = [self requestParametersWithData:data];
    
    id _any = [body objectForKey:kBDAutoTrackHeader];
    if ([_any isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *header = [_any mutableCopy];
        [header setValue:task.userUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
        [header setValue:task.userUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
        [header setValue:task.ssID forKey:kBDAutoTrackSSID];
        [header bdheader_keyFormat];
        [body setValue:header forKey:kBDAutoTrackHeader];
    }
    return body;
}

+ (NSMutableDictionary *)postBody:(BDAutoTrack *)tracker withBatchData:(BDAutoTrackBatchData *)batch
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSMutableDictionary *header = bd_requestPostHeaderParameters(tracker.appID);
    bd_addABVersions(header, tracker.appID);
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    
#if TARGET_OS_IOS
    NSDictionary *utmData = [tracker.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    [header setValue:[tracker.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    [result setValue:header forKey:kBDAutoTrackHeader];
    [result setValue:[tracker.localConfig serverTime] forKey:kBDAutoTrackTimeSync];
    [result setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];

    id batchEvents = batch.realSentData;
    if (batchEvents && [batchEvents isKindOfClass:[NSDictionary class]]) {
        [result addEntriesFromDictionary:batchEvents];
    }
    return result;
}


#pragma mark - response handling

- (BOOL)handleBatchSendCallback:(NSDictionary *)responseDict firstTime:(BOOL)first task:(BDAutoTrackBatchData *)sendingTask {
    BOOL sendingSuccess = bd_isValidResponse(responseDict) && bd_isResponseMessageSuccess(responseDict);
    NSInteger statusCode = [responseDict vetyped_integerForKey:kBDAutoTrackRequestHTTPCode];
    NSString *appID = self.appID;

    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];

    if (statusCode == 200 && sendingSuccess) {
        self.reportCount = kEventMaxCountPerRequest;
        [self.schedule scheduleWithHTTPCode:statusCode];
        [tracker.localConfig updateServerTime:responseDict];
        
        NSTimeInterval sendTime = sendingTask.sendTime;
        [sendingTask.sendingTrackData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull events, BOOL * _Nonnull stop) {
            
            [events enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSNumber *eventTime = [obj objectForKey:@"local_time_ms"];
                if ([eventTime isKindOfClass:[NSNumber class]]) {
                    NSTimeInterval delay = sendTime*1000 - [eventTime doubleValue];
                }
                if (tracker.eventBlock) {
                    NSString *event = [obj objectForKey:@"event"];
                    BDAutoTrackEventAllType type = bd_get_event_alltype(key, event);
                    if (!event) {
                        if (type == BDAutoTrackEventAllTypeLaunch) {
                            event = @"$launch";
                        } else if (type == BDAutoTrackEventAllTypeTerminate) {
                            event = @"$terminate";
                        }
                    }
                    tracker.eventBlock(BDAutoTrackEventStatusReported, type, event, obj);
                }
            }];
            
        }];
        bd_databaseRemoveTracks(sendingTask.sendingTrackID, appID);
        
        NSDictionary *blockListAll = [responseDict vetyped_dictionaryForKey:@"blocklist"];
        if (blockListAll) {
            NSArray *blockList = [blockListAll vetyped_arrayForKey:@"v3"];
            [self.eventBlcok updateBlockList:blockList];
        } else {
            [self.eventBlcok updateBlockList:@[]];
        }
        
        NSDictionary *whiteListAll = [responseDict vetyped_dictionaryForKey:@"whitelist"];
        if (whiteListAll) {
            NSArray *whiteList = [whiteListAll vetyped_arrayForKey:@"v3"];
            [self.eventBlcok updateWhiteList:whiteList];
        } else {
            [self.eventBlcok updateWhiteList:@[]];
        }
        
    } else {
        NSString *message = [responseDict vetyped_stringForKey:kBDAutoTrackMessage];
        BOOL logReportOptimizeEnabled = tracker.config.logReportOptimizeEnabled;
        RL_DEBUG(tracker, @"Uploader", @"handleBatchSendCallback Log Report Optimize Enabled: %@, Message: %@", logReportOptimizeEnabled ? @"YES" : @"NO", message);
        if (logReportOptimizeEnabled && [@"message too large error." isEqualToString: message]) {
            self.reportCount = self.reportCount / 2;
            if (self.reportCount < 1) {
                self.reportCount = 1;
            }
        } else {
            if (first) {
                sendingSuccess = [self sendTrackDataInternalFirstTime:NO task:sendingTask];
                return sendingSuccess;
            }
        }
        
        [self.schedule scheduleWithHTTPCode:statusCode];
        if (sendingTask.source == BDAutoTrackTriggerSourceRealtime) {
            bd_databaseDowngradeTracks(sendingTask.sendingTrackID, appID);
        }
    }
    
    return sendingSuccess;
}

@end

#pragma mark - C

void bd_batchUpdateTimer(CFTimeInterval interval, BOOL skipLaunch, NSString *appID) {
    BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
    [service.batchTimer updateTimerInterval:interval];
    service.batchTimer.skipLaunch = skipLaunch;
}

BOOL bd_batchIsEventInBlockList(NSString *event, NSString *appID) {
    BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
    if (service && [service.eventBlcok hasEvent:event]) {
        return YES;
    }

    return NO;
}
