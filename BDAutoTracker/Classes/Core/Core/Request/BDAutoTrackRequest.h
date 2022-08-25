//
//  BDAutoTrackRequest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackBaseRequest.h"
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackRequest;

@interface BDAutoTrackRequest : BDAutoTrackBaseRequest

@property (nonatomic, strong, nullable) BDAutoTrackRequest *nextRequest;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval requestStartTime;
@property (nonatomic, copy, readonly, nullable) NSString *eventName;

- (instancetype)initWithAppID:(NSString *)appID next:(nullable BDAutoTrackRequest *)nextRequest;

@end

NS_ASSUME_NONNULL_END
