//
//  BDAutoTrackCacheRemover.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/11/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackCacheRemover.h"

// for cache removal
#import "BDAutoTrackDefaults.h"


@implementation BDAutoTrackCacheRemover

// for cache removal

- (void)removeDefaultsForAppID:(NSString *)appID {
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
    [defaults clearAllData];
}

- (void)removeCurrentBundleFromStandardDefaultsSearchList {
    NSString *bundleID = [NSBundle.mainBundle bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removeSuiteNamed:bundleID];
}

- (void)removeCurrentBundleFromStandardDefaults {
    NSString *bundleID = [NSBundle.mainBundle bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleID];
}

/// 如果存数据的前缀函数改了，这里的前缀函数也要改
- (NSString *)storageKeyWithPrefix:(NSString *)prefix serviceVendor:(BDAutoTrackServiceVendor)vendor  {
    NSString *key = prefix;
    
    // vendor is a String Enum
    // use vendor's raw value as a suffix
    if (vendor && vendor.length > 0) {
        key = [key stringByAppendingFormat:@"_%@", vendor];
    }

    return key;
}

@end
