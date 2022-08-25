//
//  UIGestureRecognizer+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIGestureRecognizer+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import <objc/runtime.h>
#import "BDUIAutoTracker.h"
#import "UIView+AutoTrack.h"
#import "NSObject+AutoTrack.h"
#import "BDTrackConstants.h"
#import "BDAutoTrackSwizzle.h"

@interface UITapGestureRecognizer (AutoTrack)

- (instancetype)bd_initWithTarget:(id)target action:(SEL)action;

- (void)bd_addTarget:(id)target action:(SEL)action;

@end

@interface UILongPressGestureRecognizer (AutoTrack)

- (instancetype)bd_initWithTarget:(id)target action:(SEL)action;

- (void)bd_addTarget:(id)target action:(SEL)action;

@end


@implementation UIGestureRecognizer (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Init_Imp = nil;
    static IMP original_Add_Imp = nil;
    dispatch_once(&onceToken, ^{
        original_Init_Imp = bd_swizzle_instance_methodWithBlock([UIGestureRecognizer class], @selector(initWithTarget:action:), ^UIGestureRecognizer *(UIGestureRecognizer *_self, id target, SEL action){
            if (original_Init_Imp) {
                _self = ((UIGestureRecognizer* ( *)(id, SEL, id, SEL))original_Init_Imp)(_self, @selector(initWithTarget:action:), target, action);
                if ([_self isKindOfClass:[UITapGestureRecognizer class]] || [_self isKindOfClass:[UILongPressGestureRecognizer class]]) {
                    [_self removeTarget:target action:action];
                    [_self addTarget:target action:action];
                }

                return _self;
            }

            return _self;
        });

        original_Add_Imp = bd_swizzle_instance_methodWithBlock([UIGestureRecognizer class], @selector(addTarget:action:), ^(UIGestureRecognizer *_self, id target, SEL action){
            if (original_Add_Imp) {
                if ([_self isKindOfClass:[UITapGestureRecognizer class]] || [_self isKindOfClass:[UILongPressGestureRecognizer class]]) {
                    ((void ( *)(id, SEL, id, SEL))original_Add_Imp)(_self, @selector(addTarget:action:), _self, @selector(bd_trackGestureRecognizerAppClick));
                    [_self bd_trackTarget:target action:action];
                }
                ((void ( *)(id, SEL, id, SEL))original_Add_Imp)(_self, @selector(addTarget:action:), target, action);
            }
        });

    });
}

- (NSMutableSet *)bdTrackTargetInfo {
    return objc_getAssociatedObject(self, @selector(bdTrackTargetInfo));
}

- (void)setBdTrackTargetInfo:(NSMutableSet *)infos {
    objc_setAssociatedObject(self, @selector(bdTrackTargetInfo), infos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)bd_trackTarget:(id)target action:(SEL)action {
    if (!target || !action) {
        return;
    }
    //系统的一些不监听
    NSString *actionName = NSStringFromSelector(action);
    NSString *targetName = NSStringFromClass([target class]);
    if ([actionName hasPrefix:@"_"] || [targetName hasPrefix:@"_"]) {

        return;
    }
    NSMutableSet *trackInfo = [self bdTrackTargetInfo];
    if (!trackInfo) {
        trackInfo = [NSMutableSet set];
        [self setBdTrackTargetInfo:trackInfo];
    }
    [trackInfo addObject:[NSString stringWithFormat:@"(target = %@, action = %@)",targetName, actionName]];
}

- (void)bd_trackGestureRecognizerAppClick {
    if (self.state != UIGestureRecognizerStateEnded) {
        return;
    }
    NSMutableSet *targets = [self bdTrackTargetInfo];
    if (targets.count < 1) {
        return;
    }

    UIView *view = self.view;
    // webview ignore
    if (view == nil || [view bd_AutoTrackInternalItem] || [view bd_isWebViewComponent]) {
        return;
    }
    UIViewController *page = [view bd_controller];
    if (!page || [page bd_AutoTrackInternalItem]) {
        return;
    }

    NSMutableDictionary *trackInfo = [page bd_pageTrackInfo];
    [trackInfo addEntriesFromDictionary:[view bd_trackInfo]];

    /// add locationInView
    CGPoint point = [self locationInView:view];
    bd_ui_trackAddRectPoint(view.frame, point, trackInfo);
    bd_ui_trackEventWithData(BDAutoTrackEventNameGesture, trackInfo);
}

@end

