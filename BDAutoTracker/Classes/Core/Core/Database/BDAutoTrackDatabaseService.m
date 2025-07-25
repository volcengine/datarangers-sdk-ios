//
//  BDAutoTrackDatabaseService.m
//  RangersAppLog
//
//  Created by bob on 2019/9/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackTables.h"
#import "BDAutoTrackDB.h"
#import "BDAutoTrackBaseTable.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrack+Extension.h"
#import "BDCommonEnumDefine.h"
#import "BDAutoTrackEventUntils.h"
#import "RangersLog.h"
#import "BDTrackerErrorBuilder.h"

static NSString *const kExtraTableName = @"kTableName";

@interface BDAutoTrackDatabaseService ()

@property (nonatomic, strong) BDAutoTrackDatabaseQueue *databaseQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDAutoTrackBaseTable *> *tables;
@property (nonatomic, strong) BDAutoTrackBaseTable *extraTable;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, copy) NSString *databasePath;

@end

@implementation BDAutoTrackDatabaseService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameDatabase;
        self.semaphore = dispatch_semaphore_create(1);
        [self loadDatabase];
    }
    
    return self;
}

- (void)clearDatabase
{
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    RL_WARN(tracker,@"[Event]",@"DELETE ALL !!!");
    [self.tables enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDAutoTrackBaseTable * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj deleteAll];
    }];
}

- (void)loadDatabase {
    NSString *appID = self.appID;
    NSString *databasePath = bd_databaseFilePathForAppID(appID);
    self.databasePath = databasePath;
    BDAutoTrackDatabaseQueue *databaseQueue = [BDAutoTrackDatabaseQueue databaseQueueWithPath:databasePath];
    [databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:@"PRAGMA auto_vacuum = INCREMENTAL;"];
        [db executeUpdate:@"PRAGMA synchronous = NORMAL;"];
        [db executeUpdate:@"PRAGMA journal_mode = WAL;"];
    }];
    self.databaseQueue = databaseQueue;
    [self loadTables];
}

- (void)loadTables {
    NSMutableDictionary<NSString *, BDAutoTrackBaseTable *> *tables = [NSMutableDictionary new];
    BDAutoTrackDatabaseQueue *queue = self.databaseQueue;
    NSMutableArray<NSString *> *tableNames = bd_db_allTableNames(queue);

    [tableNames enumerateObjectsUsingBlock:^(NSString * tableName, NSUInteger idx, BOOL *stop) {
        BDAutoTrackBaseTable *table = [[BDAutoTrackBaseTable alloc] initWithTableName:tableName databaseQueue:queue];
        [tables setValue:table forKey:tableName];
    }];
    self.tables = tables;
    self.extraTable = [[BDAutoTrackBaseTable alloc] initWithTableName:BDAutoTrackTableExtraEvent databaseQueue:queue];;
}


- (NSUInteger)count
{
    __block NSUInteger count = 0;
    BDSemaphoreLock(self.semaphore);
    [self.tables enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, BDAutoTrackBaseTable *table, BOOL *stop) {
        if (![tableName isEqualToString:BDAutoTrackTableProfile]) {  // Profile表中的事件通过ProfileReporter上报，不通过Batch上报
            NSUInteger c = [table count];
            count += c;
        }
    }];
    BDSemaphoreUnlock(self.semaphore);
    return count;
}

- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)allTracksForBatchReport:(NSDictionary *)options {
    BDSemaphoreLock(self.semaphore);
    NSMutableDictionary<NSString *, NSArray *> *allEvents = [NSMutableDictionary new];
    [self.tables enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, BDAutoTrackBaseTable *table, BOOL *stop) {
        if (![tableName isEqualToString:BDAutoTrackTableProfile]) {  // Profile表中的事件通过ProfileReporter上报，不通过Batch上报
            NSArray *tracks = [table allTracks:options];
            if (tracks.count > 0) {
                [allEvents setValue:tracks forKey:tableName];
            }
        }
    }];
    BDSemaphoreUnlock(self.semaphore);

    return allEvents;
}

- (NSArray<NSDictionary *> *)profileTracks {
    NSArray *result;
    BDSemaphoreLock(self.semaphore);
    result = [self.tables[BDAutoTrackTableProfile] allTracks:nil];
    BDSemaphoreUnlock(self.semaphore);

    return result;
}

- (void)insertTable:(NSString *)tableName
              track:(NSDictionary *)track
            trackID:(nullable NSString *)trackID
            options:(nullable NSDictionary *)options {
    id<BDAutoTrackLogService> log = (id<BDAutoTrackLogService>)bd_standardServices(BDAutoTrackServiceNameLog, self.appID);
    if ([log respondsToSelector:@selector(sendEvent:key:)]) {
        [log sendEvent:track key:tableName];
    }
    
    BDSemaphoreLock(self.semaphore);
    BDAutoTrackBaseTable *table = [self.tables objectForKey:tableName];
    if (!table) {
        table = [[BDAutoTrackBaseTable alloc] initWithTableName:tableName databaseQueue:self.databaseQueue];
        [self.tables setValue:table forKey:tableName];
        [self.extraTable insertTrack:@{kExtraTableName:tableName} trackID:tableName withError:nil];
    }
    
    NSError *err = nil;
    BOOL success = [table insertTrack:track trackID:trackID options:options withError:&err]; 
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    NSString *session = [track objectForKey:kBDAutoTrackEventSessionID];
    
    BOOL isTerminate = [tableName isEqualToString:@"terminate"];
    if (!success) {
        RL_ERROR(tracker, @"Event",@"storing failure.");
    } else {
        RL_DEBUG(tracker, @"Event",@"storing successful.");
    }
    
    if (tracker && tracker.eventBlock) {
        BDAutoTrackEventStatus status = success ? BDAutoTrackEventStatusSaved : BDAutoTrackEventStatusSaveFailed;
        NSMutableDictionary *info = [NSMutableDictionary new];
        [info addEntriesFromDictionary:track];
        [info setValue:trackID forKey:kBDAutoTrackTableColumnTrackID];
        
        NSString *event = [track objectForKey:@"event"];
        BDAutoTrackEventAllType type = bd_get_event_alltype(tableName, event);
        if (!event) {
            if (type == BDAutoTrackEventAllTypeLaunch) {
                event = @"$launch";
            } else if (type == BDAutoTrackEventAllTypeTerminate) {
                event = @"$terminate";
            }
        }
        
        tracker.eventBlock(status, type, event, info);
    }
    BDSemaphoreUnlock(self.semaphore);
}

- (void)removeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSDictionary class]] || trackIDs.count < 1) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    __block NSUInteger count = 0;
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    [trackIDs enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, NSArray *trackID, BOOL *stop) {
        BDAutoTrackBaseTable *table = [self.tables objectForKey:tableName];
        [table removeTracksByID:trackID];
        RL_DEBUG(tracker, @"Event",@"remove %@ [%d]", tableName,trackID.count);
        count ++;
    }];
    
    
    BDSemaphoreUnlock(self.semaphore);
}

- (void)downgradeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSDictionary class]] || trackIDs.count < 1) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    __block NSUInteger count = 0;
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    [trackIDs enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, NSArray *trackID, BOOL *stop) {
        BDAutoTrackBaseTable *table = [self.tables objectForKey:tableName];
        [table downgradeTracksByID:trackID];
        RL_DEBUG(tracker, @"Event",@"downgrade priority %@ [%d]", tableName,trackID.count);
        count ++;
    }];
    
    
    BDSemaphoreUnlock(self.semaphore);
}

- (NSArray<NSString *> *)allTableNames {
    BDSemaphoreLock(self.semaphore);
    NSArray<NSString *> *tableNames = self.tables.allKeys;
    BDSemaphoreUnlock(self.semaphore);

    return tableNames;
}

- (void)vacuumDatabase {
    BDSemaphoreLock(self.semaphore);
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:@"PRAGMA incremental_vacuum;"];
    }];
    BDSemaphoreUnlock(self.semaphore);
}

- (BDAutoTrackBaseTable *)ceateTableWithName:(NSString *)tableName {
    return [[BDAutoTrackBaseTable alloc] initWithTableName:tableName databaseQueue:self.databaseQueue];
}

- (void)dealloc {
    self.tables = nil;
    self.extraTable = nil;
    [self.databaseQueue close];
}

@end

BDAutoTrackDatabaseService * bd_databaseServiceForAppID(NSString *appID) {
    BDAutoTrackDatabaseService * database = (BDAutoTrackDatabaseService *)bd_standardServices(BDAutoTrackServiceNameDatabase, appID);
    if (!database) {
        database = [[BDAutoTrackDatabaseService alloc] initWithAppID:appID];
        [database registerService];
    }
    
    return database;
}

void bd_databaseInsertTrack(NSString *tableName,
                            NSDictionary *track,
                            NSString *trackID,
                            NSString *appID,
                            NSDictionary *options) {
    
    BDAutoTrack *tracker = [[BDAutoTrackServiceCenter defaultCenter] serviceForName:BDAutoTrackServiceNameTracker appID:appID];
    NSString *event = [track objectForKey:@"event"];
    if (tracker
        && tracker.eventHandler) {
        
        BDAutoTrackEventPolicy policy = BDAutoTrackEventPolicyAccept;
        
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        [properties addEntriesFromDictionary:[track objectForKey:@"params"]?:@{}];
        
        NSUInteger eventType = 0;
    
        if ([tableName isEqualToString:@"launch"]) {
            event = @"$launch";
            eventType = BDAutoTrackDataTypeLaunch;
        }else if ([tableName isEqualToString:@"terminate"]) {
            event = @"$terminate";
            eventType = BDAutoTrackDataTypeTerminate;
        } else {
            if ([event isEqualToString:@"bav2b_click"]) {
                eventType = BDAutoTrackDataTypeClick;
            } else if ([event isEqualToString:@"bav2b_page"]) {
                eventType = BDAutoTrackDataTypePage;
            } else if ([event isEqualToString:@"$bav2b_page_leave"]) {
                eventType = BDAutoTrackDataTypePageLeave;
            } else if ([event hasPrefix:@"__profile"]) {
                eventType = BDAutoTrackDataTypeProfile;
            } else {
                eventType = BDAutoTrackDataTypeUserEvent;
            }
        }
        
        if (tracker.eventHandlerTypes & eventType) {
            NSMutableDictionary *basicData = [NSMutableDictionary dictionary];
            [basicData setValue:[track valueForKey:kBDAutoTrackGlobalEventID] forKey:kBDAutoTrackGlobalEventID];
            [basicData setValue:[track valueForKey:kBDAutoTrackLocalTimeMS] forKey:kBDAutoTrackLocalTimeMS];
            [basicData setValue:[track valueForKey:kBDAutoTrackEventSessionID] forKey:kBDAutoTrackEventSessionID];
            [basicData setValue:[track valueForKey:kBDAutoTrackEventUserID] forKey:kBDAutoTrackEventUserID];
            [basicData setValue:[track valueForKey:kBDAutoTrackEventUserIDType] forKey:kBDAutoTrackEventUserIDType];
            [basicData setValue:[track valueForKey:kBDAutoTrackSSID] forKey:kBDAutoTrackSSID];
            [basicData setValue:[track valueForKey:kBDAutoTrackABSDKVersion] forKey:kBDAutoTrackABSDKVersion];

            policy = tracker.eventHandler(eventType, event, properties, basicData);
            
            if (properties) {
                NSMutableDictionary *modifyed = [track mutableCopy];
                modifyed[@"params"] = properties;
                track = [modifyed copy];
            }
        }
        
        if (policy == BDAutoTrackEventPolicyDeny) {
            RL_WARN(tracker, @"Event",@"terminte due to EVENT HANDLER USE POLICY DENY");
            return;
        }
    }
    
    if (!event && [tableName isEqualToString:@"launch"]) {
        event = @"$launch";
    }
    if (!event && [tableName isEqualToString:@"terminate"]) {
        event = @"$terminate";
    }
    
    if (!trackID) {
        trackID = [[NSUUID UUID] UUIDString];
    }
    if (tracker && tracker.eventBlock) {
        NSMutableDictionary *info = [NSMutableDictionary new];
        [info addEntriesFromDictionary:track];
        [info setValue:trackID forKey:kBDAutoTrackTableColumnTrackID];
        tracker.eventBlock(BDAutoTrackEventStatusCreated, bd_get_event_alltype(tableName, event), event, info);
    }
    
    RL_DEBUG(tracker, @"Event",@"storing %@ (%@) \r\n%@", tableName,event, [track objectForKey:@"params"]);
        
    if ([tableName isEqualToString:@"launch"]
        || [tableName isEqualToString:@"terminate"]) {
        if ([track.allKeys containsObject:@"params"]) {
            NSMutableDictionary *modified = [track mutableCopy];
            [modified removeObjectForKey:@"params"];
            track = [modified copy];
        }
    } else if ([tableName isEqualToString:@"profile"]) {
        NSMutableDictionary *modified = [track mutableCopy];
        NSMutableDictionary *modifiedParams = [NSMutableDictionary dictionaryWithDictionary:(track[@"params"]?:@{})];
        [modifiedParams removeObjectForKey:kBDAutoTrackAPPVersion2];
        [modifiedParams removeObjectForKey:kBDAutoTrackScreenOrientation];
        modified[@"params"] = modifiedParams;
        track = [modified copy];
    }
    
    [bd_databaseServiceForAppID(appID) insertTable:tableName
                                             track:track
                                           trackID:trackID
                                           options:options];

}

void bd_databaseRemoveTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                             NSString *appID) {
    [bd_databaseServiceForAppID(appID) removeTracks:trackIDs];
}


void bd_databaseDowngradeTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                             NSString *appID) {
    [bd_databaseServiceForAppID(appID) downgradeTracks:trackIDs];
}

BDAutoTrackBaseTable * bd_databaseCeateTable(NSString *tableName, NSString *appID) {
    return [bd_databaseServiceForAppID(appID) ceateTableWithName:tableName];
}

#pragma mark - database file name and path
static NSString * bd_databaseFileComponent(void) {
    return @"cc217ca5c7e3d6e933927ae2e2569a6e";
}

NSString *bd_databaseFilePathForAppID(NSString *appID) {
    NSString *dir = bd_trackerLibraryPathForAppID(appID);
    NSString *path = [dir stringByAppendingPathComponent:bd_databaseFileComponent()];
    return path;
}
