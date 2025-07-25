//
//  BDAutoTrackEventUntils.m
//  RangersAppLog
//
//  Created by bytedance on 2022/10/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackEventUntils.h"

BDAutoTrackEventAllType bd_get_event_alltype(NSString *tableName, NSString *eventName) {
    if ([tableName isEqualToString:@"launch"]) {
        return BDAutoTrackEventAllTypeLaunch;
    } else if ([tableName isEqualToString:@"terminate"]) {
        return BDAutoTrackEventAllTypeTerminate;
    } else {
        if ([eventName isEqualToString:@"bav2b_click"]) {
            return BDAutoTrackEventAllTypeUIEvent;
        } else if ([eventName isEqualToString:@"bav2b_page"]) {
            return BDAutoTrackEventAllTypeUIEvent;
        } else if ([eventName isEqualToString:@"$bav2b_page_leave"]) {
            return BDAutoTrackEventAllTypeUIEvent;
        } else if ([eventName hasPrefix:@"__profile"]) {
            return BDAutoTrackEventAllTypeProfile;
        } else {
            return BDAutoTrackEventAllTypeEventV3;
        }
    }
}
