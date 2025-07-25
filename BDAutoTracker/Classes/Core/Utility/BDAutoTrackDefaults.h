//
//  BDAutoTrackDefaults.h
//  Aspects
//
//  Created by bob on 2019/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackDefaults : NSObject

+ (nullable instancetype)defaultsWithAppID:(NSString *)appID;

- (instancetype)initWithAppID:(NSString *)appID name:(NSString *)name;

- (BOOL)boolValueForKey:(NSString *)key;
- (double)doubleValueForKey:(NSString *)key;
- (NSInteger)integerValueForKey:(NSString *)key;
- (nullable NSString *)stringValueForKey:(NSString *)key;
- (nullable NSDictionary *)dictionaryValueForKey:(NSString *)key;
- (nullable NSArray *)arrayValueForKey:(NSString *)key;

- (id)objectForKey:(NSString *)key;

- (void)setValue:(nullable id)value forKey:(NSString *)key;
- (void)setDefaultValue:(nullable id)value forKey:(NSString *)key;
- (void)saveDataToFile;
- (void)clearAllData;

- (BOOL)isUserFirstLaunch;

- (void)refreshIsUserFirstLaunch;

- (BOOL)isAPPFirstLaunch;
@end

NS_ASSUME_NONNULL_END
