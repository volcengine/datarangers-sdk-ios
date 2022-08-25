//
//  BDAutoTrackService.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"
#import "BDAutoTrackServiceCenter.h"

NSString * const BDAutoTrackServiceNameTracker      = @"Tracker";
NSString * const BDAutoTrackServiceNameSettings     = @"Settings";
NSString * const BDAutoTrackServiceNameRegister     = @"Register";
NSString * const BDAutoTrackServiceNameDatabase     = @"Database";
NSString * const BDAutoTrackServiceNameLogger       = @"Logger";
NSString * const BDAutoTrackServiceNameRemote       = @"Remote";
NSString * const BDAutoTrackServiceNameABTest       = @"ABTest";
NSString * const BDAutoTrackServiceNameBatch        = @"Batch";
NSString * const BDAutoTrackServiceNameLog          = @"Log";
NSString * const BDAutoTrackServiceNameSimulator    = @"Simulator";
NSString * const BDAutoTrackServiceNameFilter       = @"Filter";

@implementation BDAutoTrackService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = appID;
        self.serviceName = nil;
    }
    
    return self;
}

- (void)registerService {
    [[BDAutoTrackServiceCenter defaultCenter] registerService:self];
}

- (void)unregisterService {
    [[BDAutoTrackServiceCenter defaultCenter] unregisterService:self];
}

- (BOOL)serviceAvailable {
    return YES;
}

@end
