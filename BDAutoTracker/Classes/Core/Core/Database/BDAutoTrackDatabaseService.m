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
#import "BDCommonEnumDefine.h"
#import "RangersLog.h"

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
    RL_DEBUG(self.appID, @"[PROCESS] DELETE ALL !!!");
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

#pragma mark - service API
/// caller: - [BDAutoTrackBatchService processBatchData]
/// @discussion 聚合所有表(self.tables)中的埋点数据（除了profile表）。用于BatchService上报
/// @return { table_name: [tracks_of_the_table] }
- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)allTracksForBatchReport {
    BDSemaphoreLock(self.semaphore);
    NSMutableDictionary<NSString *, NSArray *> *allEvents = [NSMutableDictionary new];
    [self.tables enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, BDAutoTrackBaseTable *table, BOOL *stop) {
        if (![tableName isEqualToString:BDAutoTrackTableProfile]) {  // Profile表中的事件通过ProfileReporter上报，不通过Batch上报
            NSArray *tracks = [table allTracks];
            if (tracks.count > 0) {
                [allEvents setValue:tracks forKey:tableName];
            }
        }
    }];
    BDSemaphoreUnlock(self.semaphore);

    return allEvents;
}

/// caller: - [BDAutoTrackProfileReporter sendProfileTrack]
/// @discussion 返回Profile表中的事件。用于Profile事件上报。
/// @return [tracks_of_profile_table]
- (NSArray<NSDictionary *> *)profileTracks {
    NSArray *result;
    BDSemaphoreLock(self.semaphore);
    result = [self.tables[BDAutoTrackTableProfile] allTracks];
    BDSemaphoreUnlock(self.semaphore);

    return result;
}

- (void)insertTable:(NSString *)tableName track:(NSDictionary *)track trackID:(NSString *)trackID {
    // 发送埋点验证请求
    id<BDAutoTrackLogService> log = (id<BDAutoTrackLogService>)bd_standardServices(BDAutoTrackServiceNameLog, self.appID);
    if ([log respondsToSelector:@selector(sendEvent:key:)]) {
        [log sendEvent:track key:tableName];
    }
    
    // 获取table对象
    BDSemaphoreLock(self.semaphore);
    BDAutoTrackBaseTable *table = [self.tables objectForKey:tableName];
    if (!table) {
        table = [[BDAutoTrackBaseTable alloc] initWithTableName:tableName databaseQueue:self.databaseQueue];
        [self.tables setValue:table forKey:tableName];
        [self.extraTable insertTrack:@{kExtraTableName:tableName} trackID:tableName];
    }
    
    // INSERT track数据到数据库
    BOOL success = [table insertTrack:track trackID:trackID];
    if (!success) {
        RL_ERROR(self.appID, @"[PROCESS] storing failure.");
    } else {
        RL_DEBUG(self.appID, @"[PROCESS] storing successful.")
    }
    BDSemaphoreUnlock(self.semaphore);
}

- (void)removeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSDictionary class]] || trackIDs.count < 1) {
        return;
    }
    BDSemaphoreLock(self.semaphore);
    __block NSUInteger count = 0;
    [trackIDs enumerateKeysAndObjectsUsingBlock:^(NSString *tableName, NSArray *trackID, BOOL *stop) {
        BDAutoTrackBaseTable *table = [self.tables objectForKey:tableName];
        [table removeTracksByID:trackID];
        count ++;
    }];
    RL_DEBUG(self.appID, @"[PROCESS] Remove tracks [%d]", count);
    BDSemaphoreUnlock(self.semaphore);
}

- (NSArray<NSString *> *)allTableNames {
    BDSemaphoreLock(self.semaphore);
    NSArray<NSString *> *tableNames = self.tables.allKeys;
    BDSemaphoreUnlock(self.semaphore);

    return tableNames;
}

/// After the events in the database file is comsumed, however the
/// file size may not change.
/// This function decreases database file size using sqlite's vacuum technique.
- (void)vacuumDatabase {
    BDSemaphoreLock(self.semaphore);
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:@"PRAGMA incremental_vacuum;"];
    }];
    BDSemaphoreUnlock(self.semaphore);
}

/// will not in allTable
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
                            NSString *appID) {
    
    //
    BDAutoTrack *tracker = [[BDAutoTrackServiceCenter defaultCenter] serviceForName:BDAutoTrackServiceNameTracker appID:appID];
    
    if (tracker
        && tracker.eventHandler) {
        
        BDAutoTrackEventPolicy policy = BDAutoTrackEventPolicyAccept;
        
        NSMutableDictionary *properties = nil;
        NSString *event = [track objectForKey:@"event"];
        NSUInteger eventType = 0;
    
        if ([tableName isEqualToString:@"launch"]) {
            event = @"$launch";
            eventType = (1 << 2);
        }else if ([tableName isEqualToString:@"terminate"]) {\
            event = @"$terminate";
            eventType = (1 << 3);
        } else {
            properties = [NSMutableDictionary dictionary];
            [properties addEntriesFromDictionary:[track objectForKey:@"params"]?:@{}];
            
            if ([event isEqualToString:@"bav2b_click"]) {
                eventType = BDAutoTrackDataTypeClick;
            } else if ([event isEqualToString:@"bav2b_page"]) {
                eventType = BDAutoTrackDataTypePage;
            } else if ([event hasPrefix:@"__profile"]) {
                [properties addEntriesFromDictionary:[track objectForKey:@"params"]?:@{}];
                eventType = BDAutoTrackDataTypeProfile;
            } else {
                eventType = BDAutoTrackDataTypeUserEvent;
            }
        }
        
        if (tracker.eventHandlerTypes & eventType) {
            policy = tracker.eventHandler(eventType, event, properties);
            
            if (properties) {
                NSMutableDictionary *modifyed = [track mutableCopy];
                modifyed[@"params"] = properties;
                track = [modifyed copy];
            }
        }
        
        if (policy == BDAutoTrackEventPolicyDeny) {
            RL_WARN(appID, @"[PROCESS] terminte due to EVENT HANDLER USE POLICY DENY");
            return;
        }
    }
    
    
    RL_DEBUG(appID, @"[PROCESS] storing %@ %@", tableName, bd_JSONRepresentation(track));
    [bd_databaseServiceForAppID(appID) insertTable:tableName
                                             track:track
                                           trackID:trackID];

}

void bd_databaseRemoveTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                             NSString *appID) {
    [bd_databaseServiceForAppID(appID) removeTracks:trackIDs];
}

BDAutoTrackBaseTable * bd_databaseCeateTable(NSString *tableName, NSString *appID) {
    return [bd_databaseServiceForAppID(appID) ceateTableWithName:tableName];
}

#pragma mark - database file name and path
static NSString * bd_databaseFileComponent(void) {
//    return @"bytedance_auto_track.sqlite";
    return @"cc217ca5c7e3d6e933927ae2e2569a6e";  // md5("bytedance_auto_track.sqlite")
}

NSString *bd_databaseFilePathForAppID(NSString *appID) {
    NSString *dir = bd_trackerLibraryPathForAppID(appID);
    NSString *path = [dir stringByAppendingPathComponent:bd_databaseFileComponent()];
    return path;
}


