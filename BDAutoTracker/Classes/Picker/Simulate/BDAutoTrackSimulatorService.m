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
#import "RangersLog.h"
#import "BDAutoTrack+Private.h"
#import "BDImageHelper.h"

static NSString *const kBDAutoTrackSimulatorServiceTimer = @"kBDAutoTrackSimulatorServiceTimer";

@interface BDAutoTrackSimulatorService ()

@property (nonatomic, copy) NSString *timerName;
@property (nonatomic, strong) dispatch_queue_t sendingQueue;
@property (nonatomic, strong) BDAutoTrackKeepRequest *request;
@property (nonatomic, assign) BOOL isUploading;

@end

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
                                                         timeInterval:1.5
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
    NSMutableArray *pages = [NSMutableArray arrayWithObject:nativePage];
    [webViews enumerateObjectsUsingBlock:^(UIView * _Nonnull webView, NSUInteger idx, BOOL * _Nonnull stop) {
        AppLogPickerView *webPickerView = [webView bd_pickerView];
        if (webPickerView) {
            NSArray *dom = [webPickerView webViewSimulatorUploadInfo];
            NSDictionary *webPage = [webPickerView simulatorUploadInfoPageInfoWithDom:dom];
            [pages addObject:webPage?:@{}];
        }
    }];
    
    NSString *base64String = [self screenshotImageData];
    
    NSDictionary *paramters = @{@"img":base64String?:@"",
                                @"pages":pages?:@[],
    };
    BDAutoTrackKeepRequest *request = self.request;
    if (request) {
        request.parameters = paramters;
        [request startRequestWithRetry:0];
    }
}

- (void)upload {
    if (self.isUploading) {
        return;
    }
    if (self.request == nil) {
        return;
    }
    self.isUploading = YES;
    
    id rootView = [self RNRootView];
    id picker = [self RNPicker];
    if (rootView && picker) {
        [self uploadReactNative:rootView picker:picker];
    } else {
        [self uploadNative];
    }
}

- (NSString *)screenshotImageData
{
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    UIImage *image = bd_picker_imageForViewWithScale(keyWindow, 2);
    NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
    
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];
    return base64String;
}

- (id)RNRootView {
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    UIViewController *rootvc = keyWindow.rootViewController;
    if ([rootvc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootvc;
        rootvc = [nav topViewController];
    }
    if ([NSStringFromClass(rootvc.view.class) isEqualToString:@"RCTRootView"]) {
        return rootvc.view;
    }
    return nil;
}
- (id)RNPicker {
    Class clz = NSClassFromString(@"RangersAppLogPicker");
    SEL instanceSEL =   NSSelectorFromString(@"shared");
    if (!clz || !instanceSEL) {
        return nil;
    }
    
    IMP instanceIMP = [clz methodForSelector:instanceSEL];
    id (*shared)(id, SEL) = (void *)instanceIMP;
    return shared(clz,instanceSEL);
}

- (void)uploadNative {
    NSMutableArray<UIView *> *webViews = [NSMutableArray array];
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    AppLogPickerView *picker = [[AppLogPickerView alloc] initWithView:keyWindow];
    NSMutableDictionary *dom = [picker simulatorUploadInfoWithWebContainer:webViews];
    
    NSUInteger zindex = 0;
    [self simulatorAddZindex:&zindex toDom:dom];
    NSMutableArray *doms = [NSMutableArray new];
    [doms addObject:dom];
    
    [self simulatorRebuildDom:dom withDoms:doms];
    [self filterDOMS:doms];
    
    picker = [self filterPicker:picker withDOMS:doms];
    
    NSDictionary *nativePage = [picker simulatorUploadInfoPageInfoWithDom:doms];
    
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
    if (tracker.config.H5AutoTrackEnabled) {
        [self upload:nativePage withWebView:webViews];
    } else {
        [self upload:nativePage withWebView:@[]];
    }
}

- (void)uploadReactNative:(id) rootView picker:(id) picker {
    SEL pageInfoFromJSSEL = NSSelectorFromString(@"pageInfoFromJS:success:failed:timeout:");
    IMP pageInfoFromJSIMP = [picker methodForSelector:pageInfoFromJSSEL];
    if (!pageInfoFromJSIMP) {
        RL_ERROR([BDAutoTrack trackWithAppID:self.appID], @"Picker", @"React Native failed to find method: pageInfoFromJS.");
        return;
    }
    
    id uploadBlock = ^(id info){
        NSMutableArray *pages;
        if ([info isKindOfClass:[NSDictionary class]]) {
            pages = [NSMutableArray arrayWithObject:info];
        } else {
            pages = [NSMutableArray new];
        }
        NSString *base64String = [self screenshotImageData];
        NSDictionary *paramters = @{@"img":base64String,
                                    @"pages":pages,
        };
        BDAutoTrackKeepRequest *request = self.request;
        if (request) {
            request.parameters = paramters;
            [request startRequestWithRetry:0];
        }
    };
    
    void (*pageInfoFromJS)(id, SEL, id, void(^)(NSDictionary *info), void(^)(NSString *message), NSTimeInterval) = (void *)pageInfoFromJSIMP;
    pageInfoFromJS(picker, pageInfoFromJSSEL, rootView, uploadBlock, uploadBlock, 500);
}

- (void)simulatorRebuildDom:(NSMutableDictionary *)dom withDoms:(NSMutableArray *)doms {
    NSString *path = [dom vetyped_stringForKey:kBDAutoTrackEventViewPath];
    NSMutableArray<NSMutableDictionary *> *children = [dom objectForKey:kBDPickerChildren];
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
    NSArray<NSMutableDictionary *> *children = [dom objectForKey:kBDPickerChildren];
    if ([children isKindOfClass:[NSArray class]] && children.count > 0) {
        for (NSMutableDictionary *ch in children) {
            [self simulatorAddZindex:zindex toDom:ch];
        }
    }
}

- (void)filterDOMS:(NSMutableArray *)doms {
    NSMutableArray *removeList = [NSMutableArray new];
    for (NSMutableDictionary *dom in doms) {
        if ([dom valueForKey:kBDPickerIgnore]) {
            [removeList addObject:dom];
        }
    }
    [doms removeObjectsInArray:removeList];
}

- (NSMutableDictionary *)filterDOM:(NSMutableDictionary *)dom {
    NSMutableArray *newChildren = [NSMutableArray new];
    for (NSMutableDictionary *child in [dom valueForKey:kBDPickerChildren]) {
        if (![child valueForKey:kBDPickerIgnore]) {
            [newChildren addObject:[self filterDOM:child]];
        }
    }
    [dom setValue:newChildren forKey:kBDPickerChildren];
    
    if ([dom valueForKey:kBDPickerIgnore] && newChildren.count == 1) {
        return [newChildren lastObject];
    }
    return dom;
}

- (AppLogPickerView *)filterPicker:(AppLogPickerView *)picker withDOMS:(NSMutableArray *)doms {
    if (doms.count != 1) {
        return picker;
    }
    
    NSString *elementPath = [[doms lastObject] valueForKey:kBDAutoTrackEventViewPath];
    AppLogPickerView *target = [self findPicker:picker byPath:elementPath];
    if (target) {
        return target;
    }
    return picker;
}

- (AppLogPickerView *)findPicker:(AppLogPickerView *)picker byPath:(NSString *)elementPath {
    if ([picker.elementPath isEqual:elementPath]) {
        return picker;
    }
    
    for (AppLogPickerView *subView in picker.subViews) {
        AppLogPickerView *target = [self findPicker:subView byPath:elementPath];
        if (target) {
            return target;
        }
    }
    return nil;
}

@end
