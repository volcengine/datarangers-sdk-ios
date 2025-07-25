//
//  BDAutoTrackALinkActivityContinuation.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackAlinkRouting.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackALinkActivityContinuation : NSObject

@property (nonatomic, weak) id<BDAutoTrackAlinkRouting> routingDelegate;

@property (nonatomic, readonly) NSString *ALinkURLString;

- (instancetype)initWithAppID:(NSString *)appID;

- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL;

- (void)continueDeferredALinkActivityWithRegisterUserInfo:(NSDictionary *)userInfo;

- (nullable NSDictionary *)tracerData;

- (nullable NSDictionary *)alink_utm_data;
@end

NS_ASSUME_NONNULL_END
