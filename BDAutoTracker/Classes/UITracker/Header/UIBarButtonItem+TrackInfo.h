//
//  UIBarButtonItem+TrackInfo.h
//  Applog
//
//  Created by bob on 2019/1/21.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (TrackInfo)

@property (nonatomic, copy) NSString *bdAutoTrackElementID;

@property (nonatomic, copy) NSString *bdAutoTrackID;

@property (nonatomic, copy) NSString *bdAutoTrackContent;

@property (nonatomic, copy) NSDictionary<NSString*, NSString *> *bdAutoTrackExtraInfos;

@property (nonatomic, copy) NSDictionary<NSString*, NSObject *> *bdAutoTrackViewProperties;

@property (nonatomic, assign) BOOL bdAutoTrackIgnoreClick;

@end

NS_ASSUME_NONNULL_END
