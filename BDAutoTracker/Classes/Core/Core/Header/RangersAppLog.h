//
//  RangersAppLog.h
//  RangersAppLog
//
//  Created by bob on 2020/4/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef RangersAppLog_h
#define RangersAppLog_h

#import <Foundation/Foundation.h>

#if __has_include(<RangersAppLog/BDCommonDefine.h>)

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import <RangersAppLog/BDCommonEnumDefine.h>
#import <RangersAppLog/BDCommonDefine.h>

#import <RangersAppLog/BDAutoTrackConfig.h>
#import <RangersAppLog/BDAutoTrackConfig+AppLog.h>

#import <RangersAppLog/BDAutoTrack.h>
#import <RangersAppLog/BDAutoTrack+SharedInstance.h>
#import <RangersAppLog/BDAutoTrack+Profile.h>
#import <RangersAppLog/BDAutoTrack+Game.h>
#import <RangersAppLog/BDAutoTrack+GameTrack.h>
#import <RangersAppLog/BDAutoTrack+Special.h>
#import <RangersAppLog/BDAutoTrack+OhayooGameTrack.h>

#import <RangersAppLog/BDAutoTrackSchemeHandler.h>
#import <RangersAppLog/BDAutoTrackNotifications.h>

#endif

#if __has_include(<RangersAppLog/UIBarButtonItem+TrackInfo.h>)
#import <RangersAppLog/UIBarButtonItem+TrackInfo.h>
#import <RangersAppLog/UIView+TrackInfo.h>
#import <RangersAppLog/UIViewController+TrackInfo.h>
#import <RangersAppLog/BDKeyWindowTracker.h>
#endif

#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemCN.h>)
#import <RangersAppLog/BDAutoTrackURLHostItemCN.h>
#endif

#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemSG.h>)
#import <RangersAppLog/BDAutoTrackURLHostItemSG.h>
#endif

#if __has_include(<RangersAppLog/BDAutoTrackURLHostItemVA.h>)
#import <RangersAppLog/BDAutoTrackURLHostItemVA.h>
#endif



#endif /* RangersAppLog_h */

