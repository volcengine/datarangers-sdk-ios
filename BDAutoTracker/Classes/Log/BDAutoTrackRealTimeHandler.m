//
//  BDAutoTrackRealTimeHandler.m
//  RangersAppLog
//
//  Created by bob on 2020/5/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRealTimeHandler.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackRealTimeService.h"

#import "BDAutoTrackLoginRequest.h"
#import "BDAutoTrackSchemeHandler+Internal.h"
#import "BDToast.h"
#import "RangersLog.h"

__attribute__((constructor)) void bdauto_log_handler(void) {
    [[BDAutoTrackSchemeHandler sharedHandler] registerInternalHandler:[BDAutoTrackRealTimeHandler new]];
}

@interface BDAutoTrackRealTimeHandler ()

@property (nonatomic, strong) BDAutoTrackLoginRequest *request;

@end

@implementation BDAutoTrackRealTimeHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = @"debug_log";
    }
    
    return self;
}

- (BOOL)handleWithAppID:(NSString *)appID
                qrParam:(NSString *)qr
                  scene:(id)scene {
    RL_DEBUG(appID, @"[URL_HANDLER] handleWithAppID:qrParam:scene start ...");
    BDAutoTrackLoginRequest *request = [[BDAutoTrackLoginRequest alloc] initWithAppID:appID];
    request.successCallback = ^{
        RL_DEBUG(appID, @"[URL_HANDLER] handleWithAppID:qrParam:scene successful ...");
        bd_picker_toastShow(@"Start verification!");
        BDAutoTrackRealTimeService *service = [[BDAutoTrackRealTimeService alloc] initWithAppID:appID];
        [service registerService];
    };
    request.failureCallback = ^{
        RL_ERROR(appID, @"[URL_HANDLER] handleWithAppID:qrParam:scene failure ...");
    };
    request.qr = qr;
    [request startRequestWithRetry:0];
    self.request = request;
    
    return YES;
}

@end
