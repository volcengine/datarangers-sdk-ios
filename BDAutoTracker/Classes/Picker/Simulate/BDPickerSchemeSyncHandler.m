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
#import "BDToast.h"
#import "RangersAppLogConfig.h"

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
        bd_picker_toastShow( @"Start uploading dom！");
        BDAutoTrackSimulatorService *service = [[BDAutoTrackSimulatorService alloc] initWithAppID:appID];
        [service registerService];
        
        // 成功登录。把「已连接上服务端圈选」的标记记为True。
        [[RangersAppLogConfig sharedInstance] setSeversidePickerAvailable:YES];
    };
    request.qr = qr;
    [request startRequestWithRetry:0];
    self.request = request;
    
    return YES;
}



@end
