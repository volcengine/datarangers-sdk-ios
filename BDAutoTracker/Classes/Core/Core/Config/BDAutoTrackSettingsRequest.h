//
//  BDAutoTrackSettingsRequest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRequest.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 拉取Settings
 URL: log_settings/
 网络接口: 异步
 */
@interface BDAutoTrackSettingsRequest : BDAutoTrackRequest

/* 上次拉取时间。用于计算距离上次拉取的时间间隔。远端可通过控制时间间隔来限流。 */
@property (nonatomic, assign) long long lastFetchTime;

@end

NS_ASSUME_NONNULL_END
