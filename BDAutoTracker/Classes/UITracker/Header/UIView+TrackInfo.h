//
//  UIView+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (TrackInfo)

@property (nonatomic, copy) NSString *bdAutoTrackElementID;

@property (nonatomic, copy) NSString *bdAutoTrackViewID;

@property (nonatomic, copy) NSString *bdAutoTrackViewContent;

@property (nonatomic, copy) NSDictionary<NSString*, NSString *> *bdAutoTrackExtraInfos;

@property (nonatomic, copy) NSDictionary<NSString*, NSObject *> *bdAutoTrackViewProperties;

@property (nonatomic, assign) BOOL bdAutoTrackIgnoreClick;

@end

NS_ASSUME_NONNULL_END
