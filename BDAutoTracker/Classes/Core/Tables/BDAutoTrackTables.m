//
//  BDAutoTrackTables.m
//  RangersAppLog
//
//  Created by bob on 2019/9/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackTables.h"
#import "BDAutoTrackDB.h"
#import "BDAutoTrackBaseTable.h"
#import "BDAutoTrackTableConstants.h"
#import "NSDictionary+VETyped.h"

NSMutableArray<NSString *> *bd_db_allTableNames(BDAutoTrackDatabaseQueue *databaseQueue) {
    NSMutableArray<NSString *> *tableNames = [NSMutableArray new];

    [tableNames addObject:BDAutoTrackTableLaunch];
    [tableNames addObject:BDAutoTrackTableTerminate];
    [tableNames addObject:BDAutoTrackTableUIEvent];
    [tableNames addObject:BDAutoTrackTableEventV3];
    [tableNames addObject:BDAutoTrackTableProfile];
    BDAutoTrackBaseTable *extraTable = [[BDAutoTrackBaseTable alloc] initWithTableName:BDAutoTrackTableExtraEvent databaseQueue:databaseQueue];
    NSArray<NSDictionary *> *allExtra = [extraTable allTracks];
    for (NSDictionary *extra in allExtra) {
        NSString *tableName = [extra vetyped_stringForKey:@"kTableName"];
        if (tableName.length > 0 && ![tableName isEqualToString:BDAutoTrackTableExtraEvent]) {
            [tableNames addObject:tableName];
        }
    }

    return tableNames;
}

