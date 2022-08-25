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

/// to continue a ALink user activity
@interface BDAutoTrackALinkActivityContinuation : NSObject

@property (nonatomic, weak) id<BDAutoTrackAlinkRouting> routingDelegate;

/// 记录当前 ALink 的 deepLink url 字符串
@property (nonatomic, readonly) NSString *ALinkURLString;

- (instancetype)initWithAppID:(NSString *)appID;

/// handle Deep Link of Universal Link
- (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL;

/// handle Deferred Deep Link
- (void)continueDeferredALinkActivityWithRegisterUserInfo:(NSDictionary *)userInfo;

/* 获取HTTP body中的tracer_data
 json path: tracer_data
 */
- (nullable NSDictionary *)tracerData;

/* some "utm_" prefixed entries
 json path: header
 */
- (nullable NSDictionary *)alink_utm_data;
@end

NS_ASSUME_NONNULL_END
