//
//  BDAutoTrackDefaults.h
//  Aspects
//
//  Created by bob on 2019/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// path: [BDAutoTrackUtility trackerDocumentPath]/{$appid}/config.plist

@interface BDAutoTrackDefaults : NSObject

+ (nullable instancetype)defaultsWithAppID:(NSString *)appID;

/// for sepecific use like database
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

/*!
 @return 是否为当前用户的首次启动。若是，则在此次启动期间对此方法的调用都将返回YES，除非切换了用户。
 */
- (BOOL)isUserFirstLaunch;

/*!
 重置底层持久化值为nil。对`isUserFirstLaunch`方法来说，相当于恢复到应用首次启动时的状态。
 */
- (void)refreshIsUserFirstLaunch;

/*!
 @return 是否为应用的首次启动。
 */
- (BOOL)isAPPFirstLaunch;
@end

NS_ASSUME_NONNULL_END
