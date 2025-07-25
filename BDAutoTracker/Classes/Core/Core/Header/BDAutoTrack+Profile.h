//
//  BDAutoTrack+Profile.h
//  Applog
//
//  Created by 朱元清 on 2020/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrack (Profile)

#pragma mark 实例方法
- (void)profileSet:(NSDictionary *)profileDict;

- (void)profileSetOnce:(NSDictionary *)profileDict;

- (void)profileUnset:(NSString *)profileName;

- (void)profileIncrement:(NSDictionary <NSString *, NSNumber *> *)profileDict;

- (void)profileAppend:(NSDictionary *)profileDict;

#pragma mark 类方法
+ (void)profileSet:(NSDictionary *)profileDict;

+ (void)profileSetOnce:(NSDictionary *)profileDict;

+ (void)profileUnset:(NSString *)profileName;

+ (void)profileIncrement:(NSDictionary <NSString *, NSNumber *> *)profileDict;

+ (void)profileAppend:(NSDictionary *)profileDict;


@end

NS_ASSUME_NONNULL_END
