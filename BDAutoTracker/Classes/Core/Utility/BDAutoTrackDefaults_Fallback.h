//
//  BDAutoTrackDefaults_Fallback.h
//  Aspects
//
//  Created by bob on 2019/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackDefaults_Fallback : NSObject

- (instancetype)initWithAppID:(NSString *)appID name:(NSString *)name;

- (NSObject *)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)saveDataToFile;

- (void)clearAllData;

@end

NS_ASSUME_NONNULL_END
