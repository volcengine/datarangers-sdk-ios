//
//  BDAutoTrack+LaunchFrom.m
//  RangersAppLog
//
//  Created by bob on 2020/6/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+LaunchFrom.h"
#import "BDAutoTrackSessionHandler.h"

@implementation BDAutoTrack (LaunchFrom)

+ (void)setLaunchFrom:(BDAutoTrackLaunchFrom)from {
    BDAutoTrackLaunchFrom oldFrom = [BDAutoTrackSessionHandler sharedHandler].launchFrom;
    if (oldFrom != BDAutoTrackLaunchFromInitialState
        && oldFrom != BDAutoTrackLaunchFromUserClick
        && from == BDAutoTrackLaunchFromUserClick) {
        return;
    }
    
    [BDAutoTrackSessionHandler sharedHandler].launchFrom = from;
}

@end
