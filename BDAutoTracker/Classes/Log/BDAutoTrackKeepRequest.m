//
//  BDAutoTrackKeepRequest.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackKeepRequest.h"

#import "NSDictionary+VETyped.h"
#import "BDAutoTrackService.h"
#import "BDAutoTrackUI.h"

@interface BDAutoTrackKeepRequest () {
    int consecutive_failures;
}

@property (nonatomic, weak) BDAutoTrackService *service;

@end

@implementation BDAutoTrackKeepRequest

- (instancetype)initWithService:(BDAutoTrackService *)service type:(BDAutoTrackRequestURLType)type {
    self = [super initWithAppID:service.appID type:type];
    if (self) {
        self.keep = YES;
        self.service = service;
        self.failureCallback = ^{
            if (service) {
                [service unregisterService];
            }
        };
    }
    
    return self;
}

- (void)startRequestWithRetry:(NSInteger)retry {
    if (!self.keep) {
        return;
    }
    [super startRequestWithRetry:retry];
}

- (BOOL)handleResponse:(NSDictionary *)response urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request{
    
    NSUInteger statusCode = ((NSHTTPURLResponse *)urlResponse).statusCode;
    if (statusCode == 200 && response) {
        BOOL keep = [response vetyped_boolForKey:@"keep"];
        self.keep = keep;
        if (!keep) {
            [BDAutoTrackUI toast:[NSString stringWithFormat:@"service abort due to server. [%lu](%@)", (unsigned long)statusCode, response]];
            [self.service unregisterService];
        }
        consecutive_failures = 0;
    } else {
        [BDAutoTrackUI toast:[NSString stringWithFormat:@"service failure. [%lu](%@)", (unsigned long)statusCode, response]];
        consecutive_failures ++;
        if (consecutive_failures == 3) {
            
            self.keep = NO;
            [BDAutoTrackUI toast:[NSString stringWithFormat:@"service abort due to client [failure more then 3 times]."]];
            [self.service unregisterService];
        }
    }
    return YES;
    
    
}

@end
