//
//  BDAutoTrackTableConstants.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/9/21.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//
#import <Foundation/Foundation.h>

#ifndef BDAutoTrackTableConstants_h
#define BDAutoTrackTableConstants_h

typedef NSString * const BDAutoTrackTable NS_TYPED_ENUM;

FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableLaunch;
FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableTerminate;
FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableEventV3;
FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableProfile;
FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableUIEvent;
FOUNDATION_EXTERN BDAutoTrackTable BDAutoTrackTableExtraEvent;

FOUNDATION_EXTERN NSString * const kBDAutoTrackTableColumnTrackID;
FOUNDATION_EXTERN NSString * const kBDAutoTrackTableColumnEntireLog;

#endif /* BDAutoTrackTableConstants_h */
