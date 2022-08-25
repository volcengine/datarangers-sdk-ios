//
//  BDAutoTrackBatchData.m
//  Applog
//
//  Created by bob on 2019/2/17.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBatchData.h"
#import "BDTrackerCoreConstants.h"

@implementation BDAutoTrackBatchData

- (void)filterData {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:3];

    NSMutableArray *event_v3 = [NSMutableArray array];
    [self.sendingTrackData enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSArray *tracks, BOOL *stop) {
        if (tracks.count < 1) {
            return;
        }
        if ([key isEqualToString:BDAutoTrackTableUIEvent]) {
            if (self.autoTrackEnabled) {
                [event_v3 addObjectsFromArray:tracks];
            }
        } else if ([key isEqualToString:BDAutoTrackTableEventV3]) {
            [event_v3 addObjectsFromArray:tracks];
        } else {
            [data setValue:tracks forKey:key];
        }
    }];

    if (event_v3.count > 0) {
        [data setValue:event_v3 forKey:BDAutoTrackTableEventV3];
    }

    self.realSentData = data;
}

@end


@implementation BDAutoTrackBatchItem

@end
