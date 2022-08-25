//
//  BDAutoTrackMonitorStore.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackMonitorStore.h"
#import "BDAutoTrackDatabaseQueue.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackDatabase.h"
#import "RangersLog.h"
#import "BDAutoTrackMetricsCollector.h"



@implementation BDAutoTrackMonitorStore {
    
    BDAutoTrackDatabaseQueue *database;
    BOOL    _databaseEnabled;
    
    NSMutableArray *_memoryCache;
    
}

static NSString *gLaunchID;

+ (void)load
{
    gLaunchID = [[NSUUID UUID] UUIDString];
}


+ (instancetype)sharedStore {
    static BDAutoTrackMonitorStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [BDAutoTrackMonitorStore new];
    });
    return store;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _memoryCache = [NSMutableArray array];
    database = [[BDAutoTrackDatabaseQueue alloc] initWithPath:[self databasePath]];
    [self initDatabase];
}

- (NSString *)databasePath
{
    NSString *libPath =  bd_trackerLibraryPath();
    return [libPath stringByAppendingPathComponent:@"monitor.dat"];
}

- (void)initDatabase
{
    NSAssert(![NSThread isMainThread], @"Can not run in main thread.");
    NSString *statement =
    @"CREATE TABLE IF NOT EXISTS monitor_metrics ("
    "metricsId  INTEGER PRIMARY KEY AUTOINCREMENT,"
    "launchId   TEXT NOT NULL,"
    "appId      TEXT NOT NULL,"
    "name       TEXT NOT NULL,"
    "category   TEXT NOT NULL,"
    "metrics    BOLB NOT NULL,"
    "remark     TEXT"
    ");";

    
    [database inDatabase:^(BDAutoTrackDatabase *db) {
        NSError *error;
        BOOL success = [db executeUpdate:statement values:nil error:&error];
        if (success) {
            self->_databaseEnabled = YES;
        } else {
            RL_ERROR(@"", @"[Monitor] database init failure due to CREATE TABLE. (%d - %@)",error.code, error.localizedDescription);
        }
    }];
    
}



#pragma mark - Public

- (void)enqueue:(NSArray<BDAutoTrackMetrics *> *)metricsList
{
    if ([metricsList count] == 0) {
        return;
    }
    static NSString *statement = @"INSERT INTO monitor_metrics (launchId,appId,name,category,metrics,remark) VALUES (?,?,?,?,?,?);";
    [database inTransaction:^(BDAutoTrackDatabase *db, BOOL *rollback) {
        [metricsList enumerateObjectsUsingBlock:^(BDAutoTrackMetrics * _Nonnull metrics, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error;
            metrics.launchId = gLaunchID;
            if(![db executeUpdate:statement values:[metrics transformSQLiteParameters] error:&error]) {
                RL_ERROR(metrics.appId, @"[Monitor] [%@-%@] flush failure due to SQLiteError %@(%d)", metrics.category,metrics.name, error.localizedDescription,error.code);
            }
        }];
    }];
}



- (void)dequeue:(NSString *)appId usingBlock:(BOOL (^)(NSArray<BDAutoTrackMetrics *> *metricsList))block
{
    if (!block) {
        return;
    }
    NSString *statement = [NSString stringWithFormat:@"SELECT * FROM monitor_metrics where appId = ? and launchId <> ? order by metricsId asc LIMIT 200;"];
    
    BOOL isClear = NO;
    do {
        NSMutableArray *metricsList = [NSMutableArray arrayWithCapacity:200];
        __block NSInteger maxMetricsId = 0;
        [self->database inDatabase:^(BDAutoTrackDatabase *db) {
            NSError *error;
            BDAutoTrackResultSet *rs = [db executeQuery:statement values:@[appId,gLaunchID] error:&error];
            while ([rs next]) {
                @try {
                    
                    NSData *metricsData = [rs dataForColumn:@"metrics"];
                    if (metricsData) {
                        BDAutoTrackMetrics *metrics = [NSKeyedUnarchiver unarchiveObjectWithData:metricsData];
                        if (!metrics) {
                            RL_ERROR(appId, @"[Monitor] unarchiveObjectWithData failure.");
                        }
                        if (metrics && [metrics.name length] > 0) {
                            [metricsList addObject:metrics];
                        }
                    }
                    maxMetricsId = [rs intForColumn:@"metricsId"];
                    
                }@catch(...){};
            }
            [rs close];
        }];
        
        RL_DEBUG(appId, @"[Monitor] load data from cache...[%d]",metricsList.count);
        if (metricsList.count < 200) {
            isClear = YES;
        }
        if (metricsList.count > 0 && block && block(metricsList)) {
            RL_DEBUG(appId, @"[Monitor] remove data cache...[%d]",metricsList.count);
            NSString *deleteStatement = @"DELETE FROM monitor_metrics where appId = ? and metricsId <= ?;";
            [self->database inDatabase:^(BDAutoTrackDatabase *db) {
                NSError *error;
                if(![db executeUpdate:deleteStatement values:@[appId,@(maxMetricsId)] error:&error]) {
                    RL_ERROR(appId, @"[Monitor] delete from cache failure due to SQLiteError %@(%d)", error.localizedDescription,error.code);
                }
            }];
        }
    } while(!isClear);
    
    [self->database inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:@"VACUUM"];
    }];
    
}


//
//
//- (NSArray<NSString *> *)appIds
//{
//    NSMutableSet *appIds = [NSMutableSet set];
//    [database inDatabase:^(BDAutoTrackDatabase *db) {
//        BDAutoTrackResultSet *rs = [db executeQuery:@"SELECT DISTINCT appId FROM monitor_metrics;"];
//
//        while ([rs next]) {
//            NSString *appId = [rs stringForColumnIndex:0];
//            if (appId.length > 0) {
//                [appIds addObject:appId];
//            }
//        }
//        [rs close];
//    }];
//    return appIds.allObjects;
//}
//
//
//- (void)dequeueAll:(BOOL (^)(NSString *appId, NSArray<BDAutoTrackMetrics *> *metricsList))callback;
//{
//    if (!callback) {
//        return;
//    }
//    [[self appIds] enumerateObjectsUsingBlock:^(NSString * _Nonnull appId, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSString *statement = [NSString stringWithFormat:@"SELECT * FROM monitor_metrics where appId = ? and launchId <> ? order by metricsId asc LIMIT 200;"];
//
//        BOOL isClear = NO;
//        do {
//            NSMutableArray *metricsList = [NSMutableArray arrayWithCapacity:200];
//            __block NSInteger maxMetricsId = 0;
//            [self->database inDatabase:^(BDAutoTrackDatabase *db) {
//                NSError *error;
//                BDAutoTrackResultSet *rs = [db executeQuery:statement values:@[appId,gLaunchID] error:&error];
//                while ([rs next]) {
//                    @try {
//
//                        NSData *metricsData = [rs dataForColumn:@"metrics"];
//                        if (metricsData) {
//                            BDAutoTrackMetrics *metrics;
//                            if (@available(iOS 11.0, *)) {
//                                NSError *subErr;
//                                metrics = [NSKeyedUnarchiver unarchivedObjectOfClass:[BDAutoTrackMetrics class] fromData:metricsData error:&subErr];
//                                if (error) {
//                                    RL_ERROR(appId, @"[Monitor] unarchivedObjectOfClass failure. (%d: %@)", subErr.code, subErr.localizedDescription);
//                                }
//                            } else {
//                                metrics = [NSKeyedUnarchiver unarchiveObjectWithData:metricsData];
//                                if (!metrics) {
//                                    RL_ERROR(appId, @"[Monitor] unarchiveObjectWithData failure.");
//                                }
//                            }
//
//                            if (metrics && [metrics.name length] > 0) {
//                                [metricsList addObject:metrics];
//                            }
//                        }
//                        maxMetricsId = [rs intForColumn:@"metricsId"];
//
//                    }@catch(...){};
//                }
//                [rs close];
//            }];
//
//            RL_DEBUG(appId, @"[Monitor] load data from cache...[%d]",metricsList.count);
//            if (metricsList.count < 200) {
//                isClear = YES;
//            }
//            if (callback && callback(appId, metricsList)) {
//                RL_DEBUG(appId, @"[Monitor] remove data cache...[%d]",metricsList.count);
//                NSString *deleteStatement = @"DELETE FROM monitor_metrics where where appId = ? and metricsId <= ?;";
//                [self->database inDatabase:^(BDAutoTrackDatabase *db) {
//                    NSError *error;
//                    if(![db executeUpdate:deleteStatement values:@[] error:&error]) {
//                        RL_ERROR(appId, @"[Monitor] delete from cache failure due to SQLiteError %@(%d)", error.localizedDescription,error.code);
//                    }
//                }];
//            }
//        } while(!isClear);
//    }];
//
//    [self->database inDatabase:^(BDAutoTrackDatabase *db) {
//        [db executeUpdate:@"VACUUM"];
//    }];
//
//}
//


#pragma mark - Queue

@end
