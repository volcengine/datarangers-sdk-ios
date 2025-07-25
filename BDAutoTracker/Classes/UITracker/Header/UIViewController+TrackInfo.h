//
//  UIViewController+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (TrackInfo)

@property (nonatomic, copy) NSString *bdAutoTrackPageTitle;

@property (nonatomic, copy) NSString *bdAutoTrackPageID;

@property (nonatomic, copy) NSString *bdAutoTrackPagePath;

@property (nonatomic, copy) NSDictionary<NSString*, NSString *> *bdAutoTrackExtraInfos;

@property (nonatomic, copy) NSDictionary<NSString*, NSObject *> *bdAutoTrackPageProperties;

@end

NS_ASSUME_NONNULL_END
