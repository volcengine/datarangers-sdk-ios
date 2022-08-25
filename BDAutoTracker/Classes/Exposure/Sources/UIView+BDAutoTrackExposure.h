//
//  UIView+BDAutoTrackExposure.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack,BDViewExposureData;

@interface UIView (BDAutoTrackExposure)

- (void)bdexposure_add:(BDAutoTrack *)tracker
                  with:(BDViewExposureData *)event;

- (void)bdexposure_clear:(BDAutoTrack *)track;

- (void)bdexposure_detectVisible:(CGRect)visibleRect;

- (BOOL)bdexposure_isObserved;

- (void)bdexposure_markIfExposed;

- (void)bdexposure_markInvisible;

- (void)bdexposure_markIfTrackable;


@end

NS_ASSUME_NONNULL_END
