//
//  BDAutoTrackKeepRequest.h
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSimpleRequest.h"


NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackService;

@interface BDAutoTrackKeepRequest : BDAutoTrackSimpleRequest

@property (nonatomic, assign) BOOL keep;

- (instancetype)initWithService:(BDAutoTrackService *)service type:(BDAutoTrackRequestURLType)type;

@end

NS_ASSUME_NONNULL_END
