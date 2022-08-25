//
//  BDAutoTrackBaseTable.m
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBaseTable.h"
#import "BDAutoTrackDB.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "RangersLog.h"
#import "NSDictionary+VETyped.h"


static const NSUInteger AppLogEventSizeLimit     = 50 * 1024; // 50 Kb

@interface BDAutoTrackBaseTable ()

@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, strong) BDAutoTrackDatabaseQueue *databaseQueue;

@end


@implementation BDAutoTrackBaseTable


- (instancetype)initWithTableName:(NSString *)tableName
                    databaseQueue:(BDAutoTrackDatabaseQueue *)databaseQueue {
    self = [super init];
    if (self) {
        self.tableName = tableName;
        self.databaseQueue = databaseQueue;
        [self checkDBFile];
    }
    
    return self;
}

- (void)deleteAll
{

    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@;", self.tableName];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:deleteSQL];
        
    }];
}

/// 执行建表SQL
- (void)checkDBFile {
    NSString *createSQL = [self createTableSql];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:createSQL];
        db.shouldCacheStatements = YES;
    }];
}

/// insert a track into the table (埋点入库)
/// Execute INSERT SQL
/// caller: - [DatabaseService insertTable: track: trackID:]
/// @param track Dic 埋点数据
/// @param trackID track_id. 若未指定则生成一个随机的UUID.
/// @return YES if SQL is performed successfully, else NO.
- (bool)insertTrack:(NSDictionary *)track trackID:(NSString *)trackID {
    // 如果没有传入trackID，则trackID默认为一个新UUID
    if (![trackID isKindOfClass:[NSString class]] || trackID.length < 1) {
        trackID = [[NSUUID UUID] UUIDString];
    }

    // JSON 序列化
    NSData *jsonData;
    __block NSError *err;
#ifdef DEBUG
    if (@available(iOS 13.0, *)) {
        jsonData = [NSJSONSerialization dataWithJSONObject:track
                                                      options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys | NSJSONWritingWithoutEscapingSlashes
                                                        error:nil];
    } else {
        jsonData = [NSJSONSerialization dataWithJSONObject:track
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:nil];
    }
#else
    jsonData = [NSJSONSerialization dataWithJSONObject:track
                                               options:0
                                                 error:&err];
#endif
    if (err) {
        return NO;
    }
    
    // 大日志处理：日志超过 50K 则丢弃，然后上报一个内部事件
    if (jsonData.length > AppLogEventSizeLimit) {
        NSMutableDictionary *errorTrack = [track mutableCopy];
        NSString *event = [errorTrack vetyped_stringForKey:kBDAutoTrackEventType] ?: @"";
        NSDictionary *param = @{@"event_name":event,@"reason":@"event param too large"};
        [errorTrack setValue:param forKey:kBDAutoTrackEventData];
        [errorTrack setValue:@"sdk_bad_event_warning" forKey:kBDAutoTrackEventType];
        
        jsonData = [NSJSONSerialization dataWithJSONObject:errorTrack
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    }

    // 将JSON Data转为JSON String
    NSString *entireLogString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (entireLogString.length <= 0) {
        return NO;
    }
    
    // 执行SQL语句
    NSString *sql = [self insertSql];
    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:sql values:@[trackID, entireLogString] error:&err];
    }];
    if (err) {
        return NO;
    }
    
    return YES;
}

/// remove many tracks from the table, specified by `trackIDs`.
/// Execute DELETE SQL.
/// caller: - [BDAutoTrackBatchService removeTracks]
/// @param trackIDs List<Str> 要删除的 track_id
- (void)removeTracksByID:(NSArray<NSString *> *)trackIDs {
    if (![trackIDs isKindOfClass:[NSArray class]] || trackIDs.count < 1) {
        return;
    }
    
    NSString *tableName = [self tableName];
    
    NSMutableArray<NSString *> *binds = [NSMutableArray new];
    NSUInteger count = trackIDs.count;
    for (NSUInteger index = 0; index < count; index++ ) {
        [binds addObject:@"?"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE track_id IN (%@);", tableName, [binds componentsJoinedByString:@","]];

    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        [db executeUpdate:sql values:trackIDs error:nil];
    }];
}

/// SELECT Query. 获取最多200条埋点数据。
/// caller: - [BDAutoTrackDatabaseService allTracks]
/// caller: bd_db_allTableNames()
/// @return List<Dic> 埋点数据组成的数组
- (NSArray<NSDictionary *> *)allTracks {
    NSMutableArray *result = [NSMutableArray array];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ limit 201;", self.tableName];

    [self.databaseQueue inDatabase:^(BDAutoTrackDatabase *db) {
        BDAutoTrackResultSet *dbResult = [db executeQuery:query];

        while ([dbResult next]) {
            @autoreleasepool {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];

                NSString *paramsJSONString = [dbResult stringForColumn:kBDAutoTrackTableColumnEntireLog];
                NSDictionary *entireLogDict = nil;
                @try {
                    entireLogDict = bd_JSONValueForString(paramsJSONString);
                } @catch (__unused NSException *e) {
                }
                if ([entireLogDict isKindOfClass:[NSDictionary class]] && entireLogDict.count > 0) {
                    [dict addEntriesFromDictionary:entireLogDict];
                }
                [dict setValue:[dbResult stringForColumn:kBDAutoTrackTableColumnTrackID] forKey:kBDAutoTrackTableColumnTrackID];
                [result addObject:dict];
            }
        }
        [dbResult close];
    }];

    return result;
}

/// 创建表SQL语句。字段：
///  track_id 整型 主键列
///  entire_log 字符串
- (NSString *)createTableSql {
        return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ \
                (track_id VARCHAR(100), \
                entire_log NVARCHAR(2000), \
                PRIMARY KEY(track_id))", self.tableName];
}

- (NSString *)insertSql {
    return [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (track_id, entire_log) VALUES(?, ?)", self.tableName];
}

@end
