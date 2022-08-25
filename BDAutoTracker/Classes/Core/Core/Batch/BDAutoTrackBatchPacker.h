//
//  BDAutoTrackBatchPacker.h
//  RangersAppLog
//
//  Created by bob on 2019/9/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackBatchData, BDAutoTrackBatchItem;

FOUNDATION_EXTERN BDAutoTrackBatchItem * bd_batchPackRawTracks(NSArray *rawTracks,
                                                               NSString *tableName,
                                                               NSString *currentSession);

FOUNDATION_EXTERN NSArray<BDAutoTrackBatchData *> *bd_batchPackAllTracks(NSDictionary<NSString *, NSArray *> *allTracks,
                                                                                NSUInteger maxCountPerTask);

FOUNDATION_EXTERN NSArray<BDAutoTrackBatchData *> *bd_batchPackAllTracksSplitByUUID(NSDictionary<NSString *, NSArray *> *allTracks,
                                                                                NSUInteger maxCountPerTask);


NS_ASSUME_NONNULL_END
