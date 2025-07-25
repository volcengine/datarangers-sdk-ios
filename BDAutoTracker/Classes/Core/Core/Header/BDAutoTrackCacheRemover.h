//
//  BDAutoTrackCacheRemover.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/11/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "RangersAppLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackCacheRemover : NSObject

- (void)removeDefaultsForAppID:(NSString *)appID;

- (void)removeCurrentBundleFromStandardDefaultsSearchList;

- (void)removeCurrentBundleFromStandardDefaults;

@end

NS_ASSUME_NONNULL_END
