//
//  BDAutoTrackRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRequest.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack.h"

#import "BDAutoTrackNetworkRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackURLHostProvider.h"

#import "RangersLog.h"

@interface BDAutoTrackRequest ()

@end

@implementation BDAutoTrackRequest

- (instancetype)initWithAppID:(NSString *)appID
                         next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID];
    if (self) {
        self.requestType = BDAutoTrackRequestURLSettings;
        self.nextRequest = nextRequest;
    }

    return self;
}

- (void)startRequestWithRetry:(NSInteger)retry {
    self.requestStartTime = CFAbsoluteTimeGetCurrent() - self.startTime;
    [super startRequestWithRetry:retry];
}

- (NSString *)requestURL {
    return [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:self.requestType appID:self.appID];
}

- (void)setStartTime:(CFTimeInterval)startTime {
    _startTime = startTime;
    if (self.nextRequest) {
        self.nextRequest.startTime = startTime;
    }
}

- (BOOL)handleResponse:(NSDictionary *)response urlResponse:(NSURLResponse *)urlResponse request:(NSDictionary *)request retry:(NSInteger)retry {
    BOOL success = [super handleResponse:response urlResponse:urlResponse request:request retry:retry];

    if (success) {
        if (self.nextRequest) {
            [self.nextRequest startRequestWithRetry:3];
        }
    }
    
    return success;
}

@end
