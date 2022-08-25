//
//  BDAutoTrackBaseTable.h
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackDatabaseQueue;

@interface BDAutoTrackBaseTable : NSObject

@property (nonatomic, copy, readonly) NSString *tableName;

- (instancetype)initWithTableName:(NSString *)tableName
                    databaseQueue:(BDAutoTrackDatabaseQueue *)databaseQueue;

- (bool)insertTrack:(NSDictionary *)track
            trackID:(nullable NSString *)trackID;

- (void)removeTracksByID:(NSArray<NSString *> *)trackIDs;

- (void)deleteAll;

- (NSArray<NSDictionary *> *)allTracks;

@end

NS_ASSUME_NONNULL_END
