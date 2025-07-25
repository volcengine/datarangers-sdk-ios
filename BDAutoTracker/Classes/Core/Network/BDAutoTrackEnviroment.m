//
//  BDAutoTrackEnviroment.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/26.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackEnviroment.h"
#import "BDAutoTrackReachability.h"
#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"

@implementation BDAutoTrackEnviroment {
    
    BDAutoTrackReachability *reachability;
    
    BOOL running;
    
}

+ (instancetype)sharedEnviroment
{
    static BDAutoTrackEnviroment *env = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        env = [BDAutoTrackEnviroment new];
    });
    return env;
}

- (instancetype)init
{
    if (self = [super init]) {
        reachability = [BDAutoTrackReachability reachability];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onNetworkChanged)
                                                     name:BDAutoTrackReachabilityDidChangeNotification
                                                   object:nil];
        
    }
    return self;
}

- (BDAutoTrackReachability *)reachability
{
    return reachability;
}

- (NSString *)connectionTypeName
{
    BDAutoTrackConnectionType connectionType = [self connectionType];
    NSString *connectionTypeName = nil;
    switch (connectionType) {
        case BDAutoTrackConnectionTypeWiFi:
            connectionTypeName = @"WIFI";
            break;
        case BDAutoTrackConnectionType2G:
            connectionTypeName = @"2G";
            break;
        case BDAutoTrackConnectionType3G:
            connectionTypeName = @"3G";
            break;
        case BDAutoTrackConnectionType4G:
            connectionTypeName = @"4G";
            break;
        case BDAutoTrackConnectionType5G:
            connectionTypeName = @"5G";
            break;
        case BDAutoTrackConnectionTypeMobile:
            connectionTypeName = @"mobile";
            break;
        default:
            connectionTypeName = nil;
            break;
    }
    return connectionTypeName;
}

- (BDAutoTrackConnectionType)connectionType
{
    BDAutoTrackConnectionType conType = BDAutoTrackConnectionTypeUnknown;
    BDAutoTrackReachabilityStatus status = self.reachability.status;
    switch (status) {
        case BDAutoTrackReachabilityStatusNotReachable:
            conType = BDAutoTrackConnectionTypeNone;
            break;
        case BDAutoTrackReachabilityStatusReachableViaWiFi:
            conType = BDAutoTrackConnectionTypeWiFi;
            break;
        case BDAutoTrackReachabilityStatusReachableViaWWAN:
            conType = BDAutoTrackConnectionTypeMobile;
            break;
    }
    return conType;
}

- (void)onNetworkChanged
{
    [[BDAutoTrack allTrackers] enumerateObjectsUsingBlock:^(BDAutoTrack * _Nonnull tracker, NSUInteger idx, BOOL * _Nonnull stop) {
        [tracker.eventGenerator addEventParameter:@{kBDAutoTrackEventNetWork:@([self connectionType])}];
    }];
}

- (BOOL)isNetworkConnected
{
    return reachability.isNetworkConnected;
}


- (void)startTrack
{
    [self resume];
    [self onNetworkChanged];
}

- (void)resume
{
    if (running) {
        return;
    }
    running = YES;
    [reachability startNotifier];
}

- (void)suspend
{
    [reachability stopNotifier];
    running = NO;
}

#pragma mark - applifecycle
- (void)onDidEnterBackground
{
    [self suspend];
}

- (void)onWillEnterForeground
{
    [self resume];
}

@end
