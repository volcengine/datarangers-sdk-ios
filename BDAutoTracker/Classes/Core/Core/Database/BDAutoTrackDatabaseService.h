//
//  BDAutoTrackDatabaseService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackBaseTable;

@interface BDAutoTrackDatabaseService : BDAutoTrackService

- (instancetype)initWithAppID:(NSString *)appID;

- (void)clearDatabase;

- (NSDictionary<NSString *, NSArray *> *)allTracksForBatchReport:(nullable NSDictionary *)options;
- (NSArray<NSDictionary *> *)profileTracks;

- (void)insertTable:(NSString *)tableName
              track:(NSDictionary *)track
            trackID:(nullable NSString *)trackID
            options:(nullable NSDictionary *)options;

- (void)removeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs;

//降级priority=0
- (void)downgradeTracks:(NSDictionary<NSString *, NSArray *> *)trackIDs;

- (NSArray<NSString *> *)allTableNames;

- (BDAutoTrackBaseTable *)ceateTableWithName:(NSString *)tableName;

- (void)vacuumDatabase;

- (NSUInteger)count;

@end

FOUNDATION_EXTERN BDAutoTrackDatabaseService * _Nullable bd_databaseServiceForAppID(NSString *appID);


FOUNDATION_EXTERN void bd_databaseInsertTrack(NSString *tableName,
                                              NSDictionary *track,
                                              NSString *_Nullable trackID,
                                              NSString *appID,
                                              NSDictionary *_Nullable options);

FOUNDATION_EXTERN void bd_databaseRemoveTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                                               NSString *appID);

FOUNDATION_EXTERN void bd_databaseDowngradeTracks(NSDictionary<NSString *, NSArray *> *trackIDs,
                                               NSString *appID);

FOUNDATION_EXTERN BDAutoTrackBaseTable * bd_databaseCeateTable(NSString *tableName, NSString *appID);

FOUNDATION_EXTERN NSString * bd_databaseFilePath(void);
FOUNDATION_EXTERN NSString *bd_databaseFilePathForAppID(NSString *appID);

NS_ASSUME_NONNULL_END
