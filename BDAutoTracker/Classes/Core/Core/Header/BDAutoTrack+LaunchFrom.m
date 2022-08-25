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
    //TTTrackerLaunchFromUserClick优先级最低，不应该把其他打开方式覆盖(除了初始的状态)
    if (oldFrom != BDAutoTrackLaunchFromInitialState
        && oldFrom != BDAutoTrackLaunchFromUserClick
        && from == BDAutoTrackLaunchFromUserClick) {
        return;
    }
    
    [BDAutoTrackSessionHandler sharedHandler].launchFrom = from;
}

@end
