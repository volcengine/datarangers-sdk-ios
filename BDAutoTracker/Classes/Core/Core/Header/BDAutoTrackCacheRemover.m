//
//  BDAutoTrackCacheRemover.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/11/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackCacheRemover.h"

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

@end
