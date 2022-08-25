//
//  NSDictionary+VETyped.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (VETyped)

- (nullable NSDictionary *)vetyped_dictionaryForKey:(NSString *)key;

- (nullable NSString *)vetyped_stringForKey:(NSString *)key;

- (nullable NSArray *)vetyped_arrayForKey:(NSString *)key;

- (double)vetyped_doubleForKey:(NSString *)key;

- (NSInteger)vetyped_integerForKey:(NSString *)key;

- (BOOL)vetyped_boolForKey:(NSString *)key;

- (long long)vetyped_longlongValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
