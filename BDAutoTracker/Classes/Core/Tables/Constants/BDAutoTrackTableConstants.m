//
//  BDAutoTrackTableConstants.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/9/21.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackTableConstants.h"

#pragma mark - 数据库表名和列名
// 表名
BDAutoTrackTable BDAutoTrackTableLaunch             = @"launch";
BDAutoTrackTable BDAutoTrackTableTerminate          = @"terminate";
BDAutoTrackTable BDAutoTrackTableEventV3            = @"event_v3";
BDAutoTrackTable BDAutoTrackTableProfile            = @"profile";
BDAutoTrackTable BDAutoTrackTableUIEvent            = @"ui_event_v3";
BDAutoTrackTable BDAutoTrackTableExtraEvent         = @"bd_extra";

// 列名
NSString * const kBDAutoTrackTableColumnTrackID     = @"track_id";
NSString * const kBDAutoTrackTableColumnEntireLog   = @"entire_log";
