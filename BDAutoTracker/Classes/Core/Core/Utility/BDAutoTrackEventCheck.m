//
//  BDAutoTrackEventCheck.m
//  RangersAppLog
//
//  Created by bytedance on 2022/6/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack.h"
#import "RangersLog.h"
#import "BDAutoTrackEventCheck.h"


static int max_value_length = 1024;
static NSString *key_regex_str = @"^[a-zA-Z0-9][a-z0-9A-Z_ .-]{1,255}$";
static NSRegularExpression *key_regex;
static NSSet *white_list;
static NSObject *lock;

#pragma private functions

NSRegularExpression *_bd_get_regex(void) {
    if (key_regex != nil) {
        return key_regex;
    }
    
    if (lock == nil) {
        lock = [NSObject new];
    }
    @synchronized (lock) {
        if (key_regex == nil) {
            NSError *error = nil;
            key_regex = [NSRegularExpression regularExpressionWithPattern:key_regex_str options:NSRegularExpressionCaseInsensitive error:&error];
        }
        return key_regex;
    }
}

bool _bd_check_key_regex(NSString *key) {
    NSRegularExpression *_regex = _bd_get_regex();
    return [_regex numberOfMatchesInString:key options:0 range:NSMakeRange(0, key.length)] > 0;
}

NSSet *_bd_get_white_list(void) {
    if (white_list == nil) {
        white_list = [NSSet setWithArray:@[
            @"$inactive",
            @"$inline",
            @"$target_uuid_list",
            @"$source_uuid",
            @"$is_spider",
            @"$source_id",
            @"$is_first_time"
        ]];
    }
    return white_list;
}


#pragma public functions

bool bd_checkEventName(BDAutoTrack *track, NSString *eventName) {
    if (eventName == nil || eventName.length == 0) {
        RL_WARN(track, @"Event",@"Event name must not be empty!");
        return NO;
    }
    if ([eventName hasPrefix:@"__"]) {
        RL_WARN(track, @"Event", @"Event [%@] name should not start with __!", eventName);
        return NO;
    }
    if ([eventName hasPrefix:@"$"]) {
        RL_WARN(track, @"Event", @"Event [%@] name should not start with $!", eventName);
        return NO;
    }
    if (!_bd_check_key_regex(eventName)) {
        RL_WARN(track, @"Event", @"Event [%@] name is invalid!", eventName);
        return NO;
    }
    return YES;
}

bool bd_checkEvent(BDAutoTrack *track, NSString *eventName, NSDictionary *params) {
    bool check = bd_checkEventName(track, eventName);
    if (params == nil) {
        return check;
    }
    
    NSSet *white_list = _bd_get_white_list();
    for (NSString *key in params) {
        if ([white_list containsObject:key]) {
            continue;
        }
        if (key.length == 0) {
            RL_WARN(track, @"Event", @"[%@] param key must not be empty!", eventName);
            check = NO;
        } else if ([key hasPrefix:@"__"]) {
            RL_WARN(track, @"Event", @"[%@] param key should not start with __!", eventName);
            check = NO;
        } else if ([key hasPrefix:@"$"]) {
            RL_WARN(track, @"Event", @"[%@] param key should not start with $!", eventName);
            check = NO;
        }
        else if (!_bd_check_key_regex(key)) {
            RL_WARN(track, @"Event", @"[%@] param key is invalid!", eventName);
            check = NO;
        }
        if ([params[key] isKindOfClass:[NSString class]] && ((NSString *) params[key]).length > max_value_length) {
            RL_WARN(track, @"Event", @"[%@] param value is limited to a maximum of %d characters!", eventName, max_value_length);
            check = NO;
        }
    }
    return check;
}

bool bd_checkCustomHeaderKey(BDAutoTrack *track, NSString *key) {
    if (key == nil || key.length == 0) {
        RL_WARN(track, @"Event",@"Header name must not be empty!");
        return NO;
    }
    if ([key hasPrefix:@"__"]) {
        RL_WARN(track, @"Event",@"Header [%@] name should not start with __!", key);
        return NO;
    }
    if ([key hasPrefix:@"$"]) {
        RL_WARN(track, @"Event",@"Header [%@] name should not start with $!", key);
        return NO;
    }
    if (!_bd_check_key_regex(key)) {
        RL_WARN(track, @"Event",@"Header [%@] name is invalid!", key);
        return NO;
    }
    return YES;
}

bool bd_checkCustomHeader(BDAutoTrack *track, NSString *key, id value) {
    bool check = YES;
    if (!bd_checkCustomHeaderKey(track, key)) {
        check = NO;
    }
    if ([value isKindOfClass:[NSString class]] && ((NSString *) value).length > max_value_length) {
        RL_WARN(track, @"Event",@"Header [%@] value is limited to a maximum of %d characters!", key, max_value_length);
        check = NO;
    }
    return check;
}

bool bd_checkCustomDictionary(BDAutoTrack *track, NSDictionary<NSString *, id> *dictionary) {
    bool check = YES;
    for (NSString *key in dictionary) {
        if (!bd_checkCustomHeader(track, key, dictionary[key])) {
            check = NO;
        }
    }
    return check;
}

bool bd_checkProfileName(BDAutoTrack *track, NSString *profileName) {
    if (profileName == nil || profileName.length == 0) {
        RL_WARN(track, @"Event",@"Profile name must not be empty!");
        return NO;
    }
    if (!_bd_check_key_regex(profileName)) {
        RL_WARN(track, @"Event",@"Profile [%@] name is invalid!", profileName);
        return NO;
    }
    return YES;
}

bool bd_checkProfileDictionary(BDAutoTrack *track, NSDictionary *dictionary) {
    bool check = YES;
    for (NSString *key in dictionary) {
        if (!bd_checkProfileName(track, key)) {
            check = NO;
        }
        if ([dictionary[key] isKindOfClass:[NSString class]] && ((NSString *) dictionary[key]).length > max_value_length) {
            RL_WARN(track, @"Event",@"Profile [%@] value is limited to a maximum of %d characters!", key, max_value_length);
            check = NO;
        }
    }
    return check;
}
