//
//  BDAutoTrackSimpleRequest.h
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDCommonDefine.h"
#import "BDAutoTrackBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackSimpleRequest : BDAutoTrackBaseRequest

@property (nonatomic, copy) NSString *qr;
@property (nonatomic, copy, nullable) NSDictionary *parameters;

- (instancetype)initWithAppID:(NSString *)appID
                         type:(BDAutoTrackRequestURLType)type;


@end

NS_ASSUME_NONNULL_END
