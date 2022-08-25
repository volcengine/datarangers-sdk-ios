//
//  BDAutoTrackABTestRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackABTestRequest.h"
#import "BDAutoTrackTimer.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackMacro.h"

#import "BDAutoTrackUtility.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackABTest.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrack+Private.h"

static NSString *const kBDAutoTrackABTestFetchTimer = @"kBDAutoTrackABTestFetchTimer";

@interface BDAutoTrackABTestRequest ()

@property (nonatomic, copy) NSString *timerName;

@end

@implementation BDAutoTrackABTestRequest

- (BDAutoTrackRequestURLType)requestType {
    return BDAutoTrackRequestURLABTest;
}

- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLABTest;
    }

    return self;
}

- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = [responseDict isKindOfClass:[NSDictionary class]] && [responseDict vetyped_stringForKey:kBDAutoTrackMessage];
    if (success && bd_isResponseMessageSuccess(responseDict)) {
        NSString *appID = self.appID;
        NSDictionary *rawData = [responseDict vetyped_dictionaryForKey:@"data"];
        [[BDAutoTrack trackWithAppID:appID].abtestManager updateABConfigWithRawData:rawData postNotification:YES];
    }

    return success;
}

@end
