//
//  BDAutoTrackBatchPacker.m
//  RangersAppLog
//
//  Created by bob on 2019/9/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBatchPacker.h"
#import "BDAutoTrackBatchData.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackSessionHandler.h"
#import "RangersLog.h"
#import "NSDictionary+VETyped.h"

BDAutoTrackBatchItem *bd_batchPackRawTracks(NSArray *rawTracks,
                                            NSString *tableName,
                                            NSString *currentSession) {
    NSMutableArray<NSDictionary *> *tracks = [NSMutableArray new];
    NSMutableArray<NSString *> *trackIDs = [NSMutableArray new];

    for (NSDictionary *track in rawTracks) {
        /// must be dict
        if (![track isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *trackID = [track vetyped_stringForKey:kBDAutoTrackTableColumnTrackID];
        /// track ID is must
        if (trackID.length < 1) {
            continue;
        }

        NSString *sessionID = [track vetyped_stringForKey:kBDAutoTrackEventSessionID] ?: @"";
        NSMutableDictionary *t = [track mutableCopy];
        [t removeObjectForKey:kBDAutoTrackTableColumnTrackID];
        /// terminate 只有在结束后才发送，占位terminate不发送
        if (![tableName isEqualToString:BDAutoTrackTableTerminate]
            || ![currentSession isEqualToString:sessionID]) {
            [tracks addObject:t];
            [trackIDs addObject:trackID];
        }
    }

    BDAutoTrackBatchItem *item = [BDAutoTrackBatchItem new];
    item.trackID = trackIDs;
    item.trackData = tracks;

    return item;
}

/// 将表数据聚合封装成 BDAutoTrackBatchData
/// @param allTracks <#allTracks description#>
/// @param maxCountPerTask <#maxCountPerTask description#>
/// @return 封装后的 BDAutoTrackBatchData
NSArray *bd_batchPackAllTracks(NSDictionary<NSString *, NSArray *> *allTracks,
                                                              NSUInteger maxCountPerTask) {
    NSString *sessionID = [BDAutoTrackSessionHandler sharedHandler].sessionID;
    NSUInteger maxEventCount = 0;
    for (NSString *tableName in allTracks.allKeys) {
        NSArray *rawTracks = [allTracks objectForKey:tableName];
        maxEventCount = MAX(maxEventCount, rawTracks.count);
    }
    /// 只取200个
    NSMutableDictionary *currentTrackData = [NSMutableDictionary new];
    NSMutableDictionary *currentTrackID = [NSMutableDictionary new];
    for (NSString *tableName in allTracks.allKeys) {
        NSArray *rawTracks = [allTracks objectForKey:tableName];
        
        NSUInteger currenRawCount = rawTracks.count;
        if (currenRawCount < 1) {
            continue;
        }
        
        NSUInteger length = MIN(currenRawCount, maxCountPerTask) ;
        NSArray * sub = [rawTracks subarrayWithRange:NSMakeRange(0, length)];
        BDAutoTrackBatchItem * item = bd_batchPackRawTracks(sub, tableName, sessionID);
        if (item.trackData.count > 0) {
            [currentTrackData setValue:item.trackData forKey:tableName];
            [currentTrackID setValue:item.trackID forKey:tableName];
        }
    }
    
    BDAutoTrackBatchData *data = [BDAutoTrackBatchData new];
    data.sendingTrackID = currentTrackID;
    data.sendingTrackData = currentTrackData;
    data.maxEventCount = maxEventCount;

    return @[data];
}


NSArray *bd_batchPackAllTracksSplitByUUID(NSDictionary<NSString *, NSArray *> *allTracks,
                                                              NSUInteger maxCountPerTask) {
    
    NSMutableDictionary *tracksByUUID = [NSMutableDictionary dictionary];
    for (NSString *tableName in allTracks.allKeys) {
        
        NSArray *rawTracks = [allTracks objectForKey:tableName];
        
        for (id track in rawTracks) {
    
            if (![track isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSString *trackID = [track vetyped_stringForKey:kBDAutoTrackTableColumnTrackID];
            if (trackID.length < 1) {
                continue;
            }
            
            NSString *uuid = [track objectForKey:@"user_unique_id"] ?: [NSNull null];
            BDAutoTrackBatchData *batch = [tracksByUUID objectForKey:uuid];
            
            if (batch.maxEventCount == maxCountPerTask) {
                continue;
            }
            if (!batch) {
                batch = [BDAutoTrackBatchData new];
                batch.tempTrackDatas = [NSMutableDictionary new];
                batch.tempTrackIDs = [NSMutableDictionary new];;
                batch.maxEventCount = 0;
                batch.userUniqueID = uuid;
                [tracksByUUID setValue:batch forKey:uuid];
            }
            if (![batch.tempTrackDatas objectForKey:tableName]) {
                [batch.tempTrackDatas setObject:[NSMutableArray new] forKey:tableName];
            }
            if (![batch.tempTrackIDs objectForKey:tableName]) {
                [batch.tempTrackIDs setObject:[NSMutableArray new] forKey:tableName];
            }
            
            if ([batch.ssID length] == 0) {
                id ssid = track[@"ssid"];
                if ([ssid isKindOfClass:[NSString class]] && [ssid length] > 0) {
                    batch.ssID = ssid;
                }
            }

            [[batch.tempTrackDatas objectForKey:tableName] addObject:track];
            [[batch.tempTrackIDs objectForKey:tableName] addObject:trackID];
            batch.maxEventCount += 1;
        }
        
    }
    
    [tracksByUUID enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, BDAutoTrackBatchData*  _Nonnull batch, BOOL * _Nonnull stop) {
        batch.sendingTrackData = [batch.tempTrackDatas copy];
        batch.sendingTrackID = [batch.tempTrackIDs copy];
        RL_DEBUG(@"[Packer] pack [UUID: %@] => %d", key, batch.maxEventCount);
    }];
    
    return [tracksByUUID allValues];
}
