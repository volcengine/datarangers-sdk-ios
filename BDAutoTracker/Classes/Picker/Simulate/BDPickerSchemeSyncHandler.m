//
//  BDPickerSchemeSyncHandler.m
//  RangersAppLog
//
//  Created by bob on 2020/5/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDPickerSchemeSyncHandler.h"
#import "BDAutoTrackLoginRequest.h"
#import "BDAutoTrackSchemeHandler+Internal.h"
#import "BDAutoTrackSimulatorService.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrackUI.h"

__attribute__((constructor)) void bdauto_picker_sync_handler(void) {
    [[BDAutoTrackSchemeHandler sharedHandler] registerInternalHandler:[BDPickerSchemeSyncHandler new]];
}

@interface BDPickerSchemeSyncHandler ()

@property (nonatomic, strong) BDAutoTrackLoginRequest *request;

@end

@implementation BDPickerSchemeSyncHandler


- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = @"sync_query";
    }
    
    return self;
}

- (BOOL)handleWithAppID:(NSString *)appID
                qrParam:(NSString *)qr
                  scene:(id)scene {
    BDAutoTrackLoginRequest *request = [[BDAutoTrackLoginRequest alloc] initWithAppID:appID];
    request.successCallback = ^{
        [BDAutoTrackUI toast:@"Picker is avalible"];
        BDAutoTrackSimulatorService *service = [[BDAutoTrackSimulatorService alloc] initWithAppID:appID];
        [service registerService];
        
        [[RangersAppLogConfig sharedInstance] setSeversidePickerAvailable:YES];
    };
    request.failureCallback = ^{
        [BDAutoTrackUI toast:@"Picker login failure"];
    };
    request.qr = qr;
    [request startRequestWithRetry:0];
    self.request = request;
    
    return YES;
}



@end
