//
//  BDAutoTrackExposureManager.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack,BDViewExposureData,BDAutoTrackConfig;


@interface BDAutoTrackExposureManager : NSObject

@property (nonatomic, assign) BOOL debugON;

@property (nonatomic, assign) BOOL observeEnabled;


+ (instancetype)sharedInstance;

- (void)startWithTracker:(BDAutoTrack *)tracker;

- (void)observe:(id)view
           with:(BDViewExposureData *)data
     forTracker:(BDAutoTrack *)tracker;

- (void)remove:(id)view
    forTracker:(BDAutoTrack *)tracker;

- (NSArray *)observedViews;


@end

NS_ASSUME_NONNULL_END
