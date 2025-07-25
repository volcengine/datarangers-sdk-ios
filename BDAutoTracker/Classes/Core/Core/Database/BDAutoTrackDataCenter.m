//
//  BDAutoTrackDataCenter.m
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackDataCenter.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackUtility.h"
#import "BDTrackerCoreConstants.h"

#import "BDAutoTrackBaseTable.h"
#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackServiceCenter.h"
#import "RangersLog.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackDatabaseService.h"

#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackRegisterService.h"

#import "NSDictionary+VETyped.h"

static NSString* const kBDAutoTrackIncreaseIdentifier   = @"kBDAutoTrackIncreaseIdentifier";
static NSString *const kBDDatabseFileCreateTime         = @"kBDDatabseFileCreateTime";

@interface BDAutoTrackDataCenter()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) BDAutoTrackDefaults *defaults;

@property (nonatomic, assign) NSInteger identifier;

@property (nonatomic, assign) NSInteger terminateEventIndex;
@property (nonatomic, copy) NSString *terminateTrackID;

@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackDataCenter


- (instancetype)initWithAppID:(NSString *)appID associatedTrack:(BDAutoTrack *)track {
    self = [super init];
    if (self) {
        self.appID = [appID mutableCopy];
        NSString *queueName = [NSString stringWithFormat:@"com.applog.database_%@",appID];
        self.internalQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        BDAutoTrackWeakSelf;
        dispatch_async(self.internalQueue, ^{
            BDAutoTrackStrongSelf;
            self.defaults = [[BDAutoTrackDefaults alloc] initWithAppID:appID name:@"tea_event_index.plist"];
        });
        self.identifier = 0;
        self.terminateEventIndex = 0;
        self.associatedTrack = track;
    }
    
    return self;
}

- (void)clearDatabase
{
    [self enqueue:^{
        [bd_databaseServiceForAppID(self.appID) clearDatabase];
    }];
}

- (void)trackWithTableName:(NSString *)tableName data:(NSDictionary *)data {
    BDAutoTrackWeakSelf;
    [self enqueue:^{
        BDAutoTrackStrongSelf;
        NSDictionary *tData = [self addEventIndex:data forTable:tableName];
        bd_databaseInsertTrack(tableName, tData, nil, self.appID,nil);
    }];
}

- (void)trackUIEventWithData:(NSDictionary *)data {
    BDAutoTrackWeakSelf;
    [self enqueue:^{
        BDAutoTrackStrongSelf;
        NSMutableDictionary *datas = [NSMutableDictionary dictionaryWithObject:@(1) forKey:@"is_bav"];

        [datas addEntriesFromDictionary:data];
        bd_addSharedEventParams(datas, self.appID);
        bd_addEventParameters(datas);
        
        bd_addScreenOrientation(datas, self.appID);
        bd_addGPSLocation(datas, self.appID);
        
        NSInteger identifier = [self trackGlobalEventID];
        [datas setValue:@(identifier) forKey:kBDAutoTrackGlobalEventID];
        bd_databaseInsertTrack(BDAutoTrackTableUIEvent, datas, nil, self.appID,nil);
        
    }];
}

- (void)trackLaunchEventWithData:(NSMutableDictionary *)data {
    BDAutoTrackWeakSelf;
    [self enqueue:^{
        BDAutoTrackStrongSelf;
        NSString *SSID = bd_registerSSID(self.appID);
        if (SSID == nil) {
            [NSThread sleepForTimeInterval:1];
        }
        
        NSInteger identifier = [self trackGlobalEventID];
        [data setValue:@(identifier) forKey:kBDAutoTrackGlobalEventID];
        self.terminateEventIndex = [self trackGlobalEventID];
        self.terminateTrackID = bd_UUID();

        bd_addSharedEventParams(data, self.appID);
        
        bd_addScreenOrientation(data, self.appID);
        bd_addGPSLocation(data, self.appID);
        
        if ([[BDAutoTrackDefaults defaultsWithAppID:self.appID] isUserFirstLaunch]) {
            [data setObject:@"true" forKey:kBDAutoTrackIsFirstTime];
        }
        
#if TARGET_OS_IOS
        NSString *ALinkURLString = self.associatedTrack.alinkActivityContinuation.ALinkURLString;
        if (ALinkURLString != nil) {
            [data setObject:ALinkURLString forKey:kBDAutoTrackDeepLinkUrl];
        }
#endif
        bd_databaseInsertTrack(BDAutoTrackTableLaunch, data, nil, self.appID,nil);
    }];
}

- (void)trackTerminateEventWithData:(NSMutableDictionary *)data {
    BDAutoTrackWeakSelf;
    [self enqueue:^{
        BDAutoTrackStrongSelf;
        if (self.terminateEventIndex < 1) {
            return;
        }

        [data setValue:@(self.terminateEventIndex) forKey:kBDAutoTrackGlobalEventID];
        bd_addSharedEventParams(data, self.appID);
        
        bd_addScreenOrientation(data, self.appID);
        bd_addGPSLocation(data, self.appID);
        
        bd_databaseInsertTrack(BDAutoTrackTableTerminate, data, self.terminateTrackID, self.appID,nil);
    }];
}

- (void)trackUserEventWithData:(NSDictionary *)data {
    [self impl_trackUserEventWithData:data insertToTable:BDAutoTrackTableEventV3];
}

- (void)trackProfileEventWithData:(NSDictionary *)data {
    [self impl_trackUserEventWithData:data insertToTable:BDAutoTrackTableProfile];
    [self enqueue:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
            [track.profileReporter sendProfileTrack];
        });
    }];
}

- (void)impl_trackUserEventWithData:(NSDictionary *)data insertToTable:(BDAutoTrackTable)tableName {
    BDAutoTrackWeakSelf;
    [self enqueue:^{
        BDAutoTrackStrongSelf;
        NSDictionary *filterdData = data;
        NSString *appID = self.appID;
        id<BDAutoTrackFilterService> filter = (id<BDAutoTrackFilterService>)bd_standardServices(BDAutoTrackServiceNameFilter, appID);
        if (filter) {
            filterdData = [filter filterEvents:data];
        }
        if (filterdData == nil) {
            return;
        }
        
        NSMutableDictionary *datas = [NSMutableDictionary dictionary];

        [datas addEntriesFromDictionary:data];
        bd_addSharedEventParams(datas, self.appID);
        bd_addEventParameters(datas);
        
        bd_addScreenOrientation(datas, self.appID);
        bd_addGPSLocation(datas, self.appID);
        
        NSInteger identifier = [self trackGlobalEventID];
        [datas setValue:@(identifier) forKey:kBDAutoTrackGlobalEventID];
        bd_databaseInsertTrack(tableName, datas, nil, self.appID,nil);
        
        
    }];
}

- (void)enqueue:(dispatch_block_t)block {
    if (self.associatedTrack.localConfig.trackEventEnabled) {
        dispatch_async(self.internalQueue, block);
    }
}

- (NSMutableDictionary *)addEventIndex:(NSDictionary *)originData forTable:(NSString *)tableName {
    NSMutableDictionary *trackData = [NSMutableDictionary dictionaryWithDictionary:originData];
    NSString *key = [kBDAutoTrackIncreaseIdentifier stringByAppendingFormat:@"_%@",tableName];
    NSInteger identifier = [self.defaults integerValueForKey:key];

    identifier++;

    [trackData setValue:@(identifier) forKey:kBDAutoTrackGlobalEventID];
    [self.defaults setValue:@(identifier) forKey:key];
    [self.defaults saveDataToFile];

    return trackData;
}

- (NSInteger)trackGlobalEventID {
    NSInteger identifier = self.identifier;

    if (identifier < 1) {
        identifier = [self.defaults integerValueForKey:kBDAutoTrackIncreaseIdentifier];
    }

    identifier++;
    self.identifier = identifier;
    [self.defaults setValue:@(identifier) forKey:kBDAutoTrackIncreaseIdentifier];
    [self.defaults saveDataToFile];

    return identifier;
}

@end
