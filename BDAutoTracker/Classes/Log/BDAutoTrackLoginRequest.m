//
//  BDAutoTrackLoginRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackLoginRequest.h"

#import "BDToast.h"
#import "BDTrackerCoreConstants.h"

@implementation BDAutoTrackLoginRequest

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID type:BDAutoTrackRequestURLSimulatorLogin];
    if (self) {
        self.failureCallback = ^{
            bd_picker_toastShow(@"Login failed! Please try again.");
        };
    }
    
    return self;
}

@end
