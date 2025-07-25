//
//  BDAutoTrackEventGenerator.m
//  RangersAppLog
//
//  Created by bytedance on 7/21/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackEventGenerator.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrack+Private.h"
#import <stdatomic.h>
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackerDefines.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDTrackerErrorBuilder.h"
#import "BDAutoTrackerDefines.h"
#import "BDAutoTrackNotifications.h"

#import "BDAutoTrackMacro.h"


typedef void(^BDAutoTrackOnEventStored)(id tracker, NSString * _Nullable type, NSDictionary *event);


@interface BDAutoTrackEventGenerator () {
    
    dispatch_queue_t eventQueue;
    void* onEventQueueTag;
    dispatch_queue_t dispatchQueue;
    
    NSMutableDictionary *globalUserParameter;
    NSMutableDictionary *globalEventParameter;
    
    NSString *appId;
    atomic_int_fast64_t sessionId;
    
    NSUInteger bulkSize;
    
    atomic_int_fast64_t counter;
    
}

@property (nonatomic, copy) BDAutoTrackOnEventStored onEventStored;

@property (atomic, copy) NSString *currentSession;

@end

@implementation BDAutoTrackEventGenerator


#pragma mark - init
+ (instancetype)generatorForTrack:(BDAutoTrack *)tracker
{
    if (!tracker) {
        return nil;
    }
    BDAutoTrackEventGenerator *generator = [BDAutoTrackEventGenerator new];
    generator.tracker = tracker;
    [generator commonInit];
    return generator;
}

- (void)commonInit
{
    if (!self.tracker) {
        return;
    }
    self->appId = self.tracker.appID;
    self->sessionId = 0;
    
    [self initThread];
    
    globalEventParameter = [NSMutableDictionary dictionary];
    globalUserParameter = [NSMutableDictionary dictionary];
    
    
    self.onEventStored = ^(BDAutoTrack* tracker, NSString * _Nullable type, NSDictionary *event) {
        if ([type isKindOfClass:NSString.class] && [type isEqualToString:BDAutoTrackTableProfile]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [tracker.profileReporter sendProfileTrack];
            });
        }
    };
    
    [self setBatchTriggerBulk:self.tracker.remoteConfig.batchBulkSize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRemoteConfigDidUpdate:) name:BDAutoTrackRemoteConfigDidUpdateNotification object:nil];
    
    [self loadCurrentEventCount];

}

- (void)onRemoteConfigDidUpdate:(NSNotification *)noti
{
    NSString *appId = [noti.userInfo objectForKey:kBDAutoTrackNotificationAppID];
    if ([self.tracker.appID isEqualToString:appId]) {
        [self setBatchTriggerBulk:self.tracker.remoteConfig.batchBulkSize];
    }
}

- (void)loadCurrentEventCount
{
    [self async:^{
        self->counter = [bd_databaseServiceForAppID(self.tracker.appID) count];
        RL_DEBUG(self.tracker, @"Event", @"event count in cahce : %llu.", self->counter);
        [self _bulkBatchIfNeed];
    }];
}

- (NSDictionary *)validateAndCopyParameter:(NSDictionary *)parameter
{
    if ([parameter isKindOfClass:NSDictionary.class] &&  ![NSJSONSerialization isValidJSONObject:parameter]) {
        RL_WARN(self.tracker, @"Event", @"parameter is NOT ValidJSONObject.");
        return @{};
    }
    if (parameter.count == 0) {
        return parameter;
    }
    return [[NSDictionary alloc] initWithDictionary:parameter copyItems:YES].copy;
}

#pragma mark - global parameters

- (void)addGlobalUserParameter:(NSDictionary <NSString *,id> *)parameter
{
    NSDictionary *dict = [self validateAndCopyParameter:parameter];
    if ([dict count] == 0) {
        return;
    }
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        RL_DEBUG(block_self.tracker, @"Event", @"add Event Parameters : %@", dict);
        [block_self->globalUserParameter addEntriesFromDictionary:dict];
    }];
}

- (void)removeGlobalUserParameterForKey:(NSString *)key
{
    if (![key isKindOfClass:NSString.class]) {
        return;
    }
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        RL_DEBUG(block_self.tracker, @"Event", @"remove Parameters : %@", key);
        [block_self->globalUserParameter removeObjectForKey:key];
    }];
}

- (void)addEventParameter:(NSDictionary <NSString *,id> *)parameter
{
    NSDictionary *dict = [self validateAndCopyParameter:parameter];
    if ([dict count] == 0) {
        return;
    }
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        RL_DEBUG(block_self.tracker, @"Event", @"add Event Parameters : %@", dict);
        [block_self->globalEventParameter addEntriesFromDictionary:dict];
    }];
}

- (void)removeEventParameterForKey:(NSString *)key
{
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        RL_DEBUG(block_self.tracker, @"Event", @"remove Event Parameter : %@", key);
        [block_self->globalEventParameter removeObjectForKey:key];
    }];
}

#pragma mark - event generator

- (BOOL)trackLaunch:(NSDictionary *)launch_
{
    self.currentSession = [launch_ objectForKey:kBDAutoTrackEventSessionID];
    NSDictionary *launch = [[NSDictionary alloc] initWithDictionary:launch_ copyItems:YES];
    
    BDAutoTrackWeakSelf;
    [self async:^{
        BDAutoTrackStrongSelf;
        if (bd_batchIsEventInBlockList(@"app_launch", self.tracker.appID)) {
            RL_WARN(self,@"[Event launch]",@"terminate due to EVENT IN BLOCK LIST.");
            return;
        }
        
        NSMutableDictionary *launchObject = [NSMutableDictionary dictionary];
        [launchObject addEntriesFromDictionary:launch];
        
        NSString *sessionId = [launch objectForKey:kBDAutoTrackEventSessionID];
        [self addEventParameter:@{kBDAutoTrackEventSessionID: sessionId?:@""}];
        
        [self handleGeneralParameters:launchObject];
        
        
        if ([[BDAutoTrackDefaults defaultsWithAppID:self.tracker.appID] isUserFirstLaunch]) {
            [launchObject setObject:@"true" forKey:kBDAutoTrackIsFirstTime];
        }
        
        // add deeplink url
#if TARGET_OS_IOS
        NSString *ALinkURLString = self.tracker.alinkActivityContinuation.ALinkURLString;
        if (ALinkURLString != nil) {
            [launchObject setObject:ALinkURLString forKey:kBDAutoTrackDeepLinkUrl];
        }
#endif
        
        [self dispatchEvent:launchObject type:BDAutoTrackTableLaunch options:nil];
        
    }];
    
    return YES;
    
}

- (BOOL)trackTerminate:(NSDictionary *)terminate_
{
    NSDictionary *terminate = [[NSDictionary alloc] initWithDictionary:terminate_ copyItems:YES];
    
    BDAutoTrackWeakSelf;
    [self async:^{
        BDAutoTrackStrongSelf;
        if (bd_batchIsEventInBlockList(@"app_terminate", self.tracker.appID)) {
            RL_WARN(self,@"[Event terminate]",@"terminate due to EVENT IN BLOCK LIST.");
            return;
        }
        
        NSMutableDictionary *terminateObject = [NSMutableDictionary dictionary];
        [terminateObject addEntriesFromDictionary:terminate];
        
        [self handleGeneralParameters:terminateObject];
        
        [self dispatchEvent:terminateObject type:BDAutoTrackTableTerminate options:nil];
        
    }];
    return YES;
}


- (BOOL)trackEvent:(NSString *)event_
         parameter:(NSDictionary <NSString *,id> *)parameter_
           options:(BDAutoTrackEventOption *)opt
{
    NSString *session = self.currentSession;

    if (![event_ isKindOfClass:[NSString class]] || event_.length < 1) {
        RL_WARN(self,@"[Event]",@"terminate due to EMPTY EVENT");
        return NO;
    }
    if (parameter_ && ![NSJSONSerialization isValidJSONObject:parameter_]) {
        RL_ERROR(self.tracker, @"Event", @"Drop event[%@] due to INVALID JSON parameter. ", event_ ?: @"");
        return NO;
    }
    
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *event = [event_ copy];
    NSDictionary *parameter = [[NSDictionary alloc] initWithDictionary:parameter_ copyItems:YES];
    BDAutoTrackEventOption *option = opt;
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        NSString *curren_session = [self->globalEventParameter objectForKey:kBDAutoTrackEventSessionID];
        
            
        if (bd_batchIsEventInBlockList(event, self.tracker.appID)) {
            RL_WARN(self,@"[Event]",@"terminate due to EVENT IN BLOCK LIST. (%@)",event);
            return;
        }
        
        NSMutableDictionary *eventObject = [NSMutableDictionary dictionary];
        [eventObject setValue:event forKey:kBDAutoTrackEventType];
        
        NSMutableDictionary *mutableParameter = [parameter mutableCopy];
        [eventObject setValue:mutableParameter forKey:kBDAutoTrackEventData];

        
        id<BDAutoTrackFilterService> filter = (id<BDAutoTrackFilterService>)bd_standardServices(BDAutoTrackServiceNameFilter, self.tracker.appID);
        if (filter) {
            if([filter filterEvents:eventObject] == nil) {
                RL_WARN(self.tracker, @"Event", @"Drop event(%@) due to user defined filter.", event);
                return;
            }
        }
        
        [eventObject setValue:@((long long)(currentTimeInterval*1000)) forKey:kBDAutoTrackLocalTimeMS]; //local_time_ms
        [eventObject setValue:bd_formatDateString(currentTimeInterval) forKey:kBDAutoTrackEventTime]; //datetime
        
        [self handleGeneralParameters:eventObject];
        
        [self handleEvent:eventObject withEvent:option];
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        if([self.tracker.remoteConfig.realTimeEvents containsObject:event]) {
            [options setValue:@(BDAutoTrackEventPriorityRealtime) forKey:@"priority"];
        }
        
        [block_self dispatchEvent:eventObject type:BDAutoTrackTableEventV3 options:options];

    }];
    
    return YES;
}

- (BOOL)trackEventType:(NSString *)type_
             eventBody:(NSDictionary *)event_
               options:(nullable id)opt
{
    if (event_ && ![NSJSONSerialization isValidJSONObject:event_]) {
        RL_ERROR(self.tracker, @"Event", @"Drop event[%@] due to INVALID JSON parameter. ", event_ ?: @"");
        return NO;
    }
    NSDictionary *event = [[NSDictionary alloc] initWithDictionary:event_ copyItems:YES];
    NSString *type = [type_ copy];
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    __weak typeof(self) weakself = self;
    [self async:^{
        typeof(self) block_self = weakself;
        if (!block_self) {
            return;
        }
        
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
       
        if ([type isEqualToString:BDAutoTrackTableUIEvent]) {
            NSString *eventKey = [event objectForKey:@"event"];
            NSString *curren_session = [self->globalEventParameter objectForKey:kBDAutoTrackEventSessionID];
            if (bd_batchIsEventInBlockList(eventKey, self.tracker.appID)) {
                RL_WARN(self,@"[Event]",@"terminate due to EVENT IN BLOCK LIST. (%@)",eventKey);
                return;
            }
            if([self.tracker.remoteConfig.realTimeEvents containsObject:eventKey]) {
                [options setValue:@(BDAutoTrackEventPriorityRealtime) forKey:@"priority"];
            }
        }
        
        NSMutableDictionary *eventObject = [NSMutableDictionary dictionary];
        //shared event key
        [eventObject setValue:@((long long)(currentTimeInterval*1000)) forKey:kBDAutoTrackLocalTimeMS]; //local_time_ms
        [eventObject setValue:bd_formatDateString(currentTimeInterval) forKey:kBDAutoTrackEventTime]; //datetime
        [eventObject addEntriesFromDictionary:event];
        [self handleGeneralParameters:eventObject];
        
        //dispatch next
        [block_self dispatchEvent:eventObject type:type options:options];

    }];
    
    return YES;
}


- (void)handleEvent:(NSMutableDictionary *)event
           withEvent:(BDAutoTrackEventOption *)option
{
    // handle additional abtesting vids
    if (option.abtestingExperiments.length > 0) {
        NSString *existVids = [event objectForKey:kBDAutoTrackABSDKVersion];
        NSMutableSet *vidset = [NSMutableSet set];
        if (existVids.length > 0) {
            [vidset addObjectsFromArray:[existVids componentsSeparatedByString:@","]?:@[]];
        }
        [vidset addObjectsFromArray:[option.abtestingExperiments componentsSeparatedByString:@","]?:@[]];
        [event setValue:[vidset.allObjects componentsJoinedByString:@","]  forKey:kBDAutoTrackABSDKVersion];
    }
}


- (void)handleGeneralParameters:(NSMutableDictionary *)event
{
    NSDictionary *currentGlobalParamters = [self->globalEventParameter copy];
    [event addEntriesFromDictionary:currentGlobalParamters];
    //tea_event_index
    [event setValue:@([self.tracker.dataCenter trackGlobalEventID]) forKey:kBDAutoTrackGlobalEventID];
    
    bd_addScreenOrientation(event, self.tracker.appID);
    bd_addGPSLocation(event, self.tracker.appID);
    bd_addAppVersion(event);
}


- (void)dispatchEvent:(id)event
                 type:(NSString *)type
              options:(nullable NSDictionary *)options;
{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatchQueue, ^{
        
        typeof(weak_self) strong_self = weak_self;
        if (!strong_self) {
            return;
        }
        
        bd_databaseInsertTrack(type, event, nil, self.tracker.appID, options);
       
        NSInteger priority = [[options objectForKey:@"priority"] integerValue];
        if (strong_self.onEventStored) {
            strong_self.onEventStored(strong_self.tracker, type, event);
        }
        if (priority == BDAutoTrackEventPriorityRealtime) {
            BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, self.tracker.appID);
            [service realtimeEventBatch];
        } else {
            //非实时埋点触发
            self->counter ++;
            [self _bulkBatchIfNeed];
        }
    });
}

- (dispatch_queue_t)executionQueue
{
    return self->dispatchQueue;
}

#pragma mark - bulk

- (void)setBatchTriggerBulk:(NSUInteger)bulk
{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatchQueue, ^{
        
        typeof(weak_self) strong_self = weak_self;
        if (!strong_self) {
            return;
        }
        self->bulkSize = bulk;
        [self _bulkBatchIfNeed];
        
    });
}

- (void)restoreBulkCounter
{
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatchQueue, ^{
        typeof(weak_self) strong_self = weak_self;
        if (!strong_self) {
            return;
        }
        self->counter = 0;
    });
}


- (void)_bulkBatchIfNeed
{
    if (self->bulkSize == 0) {
        return;
    }
    if(self->counter >= self->bulkSize) {
        RL_DEBUG(self.tracker, @"Event", @"bulk batch trigger (%llu : %llu).", self->counter, self->bulkSize);
        BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, self.tracker.appID);
        [service sendTrackDataFrom:BDAutoTrackTriggerSourceEventCacheSize];
        self->counter = 0;
    }
}



#pragma mark - thread

- (void)initThread
{
    NSString *name = [NSString stringWithFormat:@"volcengine.tracker.event.%@.%p",self.tracker.appID, self];
    eventQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    onEventQueueTag = &onEventQueueTag;
    void *nonNullUnusedPointer = (__bridge void *)self;
    dispatch_queue_set_specific(eventQueue, onEventQueueTag, nonNullUnusedPointer, NULL);
    
    NSString *dispatchQueueName = [NSString stringWithFormat:@"volcengine.tracker.event.dispatcher.%@.%p",self.tracker.appID, self];
    dispatchQueue = dispatch_queue_create([dispatchQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
}

- (void)async:(dispatch_block_t)block
{
    if (dispatch_get_specific(onEventQueueTag))
        block();
    else
        dispatch_async(eventQueue, block);
}

@end
