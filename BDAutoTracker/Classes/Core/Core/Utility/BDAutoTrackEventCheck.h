//
//  BDAutoTrackEventCheck.h
//  RangersAppLog
//
//  Created by bytedance on 2022/6/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack.h"


NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN bool bd_checkEventName(BDAutoTrack *track, NSString *eventName);

FOUNDATION_EXTERN bool bd_checkEvent(BDAutoTrack *track, NSString *eventName, NSDictionary *params);

FOUNDATION_EXTERN bool bd_checkCustomHeaderKey(BDAutoTrack *track, NSString *key);

FOUNDATION_EXTERN bool bd_checkCustomHeader(BDAutoTrack *track, NSString *key, id value);

FOUNDATION_EXTERN bool bd_checkCustomDictionary(BDAutoTrack *track, NSDictionary<NSString *, id> *dictionary);

FOUNDATION_EXTERN bool bd_checkProfileName(BDAutoTrack *track, NSString *profileName);

FOUNDATION_EXTERN bool bd_checkProfileDictionary(BDAutoTrack *track, NSDictionary *dictionary);

NS_ASSUME_NONNULL_END


