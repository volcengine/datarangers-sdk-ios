//
//  BDAutoTrackSimulatorService.m
//  RangersAppLog
//
//  Created by bob on 2020/6/1.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSimulatorService.h"
#import "BDAutoTrackTimer.h"
#import "BDAutoTrackMacro.h"
#import "BDAutoTrackKeepRequest.h"
#import "BDPickerConstants.h"
#import "BDKeyWindowTracker.h"
#import "BDPickerView.h"
#import "UIView+Picker.h"
#import "BDScreenHelper.h"
#import "BDTrackConstants.h"
#import "BDTrackerCoreConstants.h"
#import "NSDictionary+VETyped.h"

static NSString *const kBDAutoTrackSimulatorServiceTimer = @"kBDAutoTrackSimulatorServiceTimer";

@interface BDAutoTrackSimulatorService ()

@property (nonatomic, copy) NSString *timerName;
@property (nonatomic, strong) dispatch_queue_t sendingQueue;
@property (nonatomic, strong) BDAutoTrackKeepRequest *request;
@property (nonatomic, assign) BOOL isUploading;

@end

/// DOM上传服务。
@implementation BDAutoTrackSimulatorService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.isUploading = NO;
        self.serviceName = BDAutoTrackServiceNameSimulator;
        self.timerName = [kBDAutoTrackSimulatorServiceTimer stringByAppendingFormat:@"_%@",appID];
    }
    
    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)registerService {
    [super registerService];
    [self startTimer];
}

- (void)unregisterService {
    [super unregisterService];
    [self stopTimer];
}

- (void)startTimer {
    BDAutoTrackKeepRequest *request = self.request;
    if (request) {
        request.keep = NO;
    }
    request = [[BDAutoTrackKeepRequest alloc] initWithService:self type:BDAutoTrackRequestURLSimulatorUpload];
    self.request = request;
    BDAutoTrackWeakSelf;
    request.successCallback = ^{
        BDAutoTrackStrongSelf;
        self.isUploading = NO;
    };
    dispatch_block_t action = ^{
        BDAutoTrackStrongSelf;
        [self upload];
    };
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:self.timerName
                                                         timeInterval:1
                                                                queue:dispatch_get_main_queue()
                                                              repeats:YES
                                                               action:action];
}

- (void)stopTimer {
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:self.timerName];
    self.request.keep = NO;
    self.request = nil;
}

- (void)upload:(NSDictionary *)nativePage withWebView:(NSArray<UIView *> *)webViews {
    if (webViews.count > 0) {
        AppLogPickerView *testPickerView = [webViews.lastObject bd_pickerView];
        if (testPickerView == nil) {
            BDAutoTrackWeakSelf;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                BDAutoTrackStrongSelf;
                [self upload:nativePage withWebView:webViews];
            });
            return;
        }
    }
    
    NSMutableArray *pages = [NSMutableArray arrayWithObject:nativePage];
    [webViews enumerateObjectsUsingBlock:^(UIView * _Nonnull webView, NSUInteger idx, BOOL * _Nonnull stop) {
        AppLogPickerView *webPickerView = [webView bd_pickerView];
        NSArray *dom = [webPickerView webViewSimulatorUploadInfo];
        NSDictionary *webPage = [webPickerView simulatorUploadInfoPageInfoWithDom:dom];
        [pages addObject:webPage];
    }];
    
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    UIImage *image = bd_picker_imageForView(keyWindow);
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];
    NSDictionary *paramters = @{@"img":base64String,
                                @"pages":pages,
    };
    BDAutoTrackKeepRequest *request = self.request;
    if (request) {
        request.parameters = paramters;
        [request startRequestWithRetry:0];
    }
}

/// 上传DOM
- (void)upload {
    if (self.isUploading) {
        return;
    }
    if (self.request == nil) {
        return;
    }
    self.isUploading = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPickerStartNotification object:nil];
    
    NSMutableArray<UIView *> *webViews = [NSMutableArray array];
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    AppLogPickerView *picker = [[AppLogPickerView alloc] initWithView:keyWindow];
    NSMutableDictionary *dom = [picker simulatorUploadInfoWithWebContainer:webViews];
    
    NSUInteger zindex = 0;
    [self simulatorAddZindex:&zindex toDom:dom];
    NSMutableArray *doms = [NSMutableArray new];
    [doms addObject:dom];
    
    [self simulatorRebuildDom:dom withDoms:doms];
    
    NSDictionary *nativePage = [picker simulatorUploadInfoPageInfoWithDom:doms];
    [self upload:nativePage withWebView:webViews];
}

- (void)simulatorRebuildDom:(NSMutableDictionary *)dom withDoms:(NSMutableArray *)doms {
    NSString *path = [dom vetyped_stringForKey:kBDAutoTrackEventViewPath];
    NSMutableArray<NSMutableDictionary *> *children = [dom objectForKey:@"children"];
    NSMutableArray *childrenToRemove = [NSMutableArray new];
    
    if ([children isKindOfClass:[NSArray class]] && children.count > 0) {
        for (NSMutableDictionary *ch in children) {
            NSString *cpath = [ch vetyped_stringForKey:kBDAutoTrackEventViewPath];
            if (![cpath hasPrefix:path]) {
                [childrenToRemove addObject:ch];
                [doms addObject:ch];
            }
            
            [self simulatorRebuildDom:ch withDoms:doms];
        }
    }
    
    if (childrenToRemove.count > 0) {
        [children removeObjectsInArray:childrenToRemove];
    }
}

- (void)simulatorAddZindex:(NSUInteger *)zindex toDom:(NSMutableDictionary *)dom {
    [dom setValue:@(*zindex) forKey:@"zIndex"];
    *zindex= (*zindex + 1);
    NSArray<NSMutableDictionary *> *children = [dom objectForKey:@"children"];
    if ([children isKindOfClass:[NSArray class]] && children.count > 0) {
        for (NSMutableDictionary *ch in children) {
            [self simulatorAddZindex:zindex toDom:ch];
        }
    }
}

@end
