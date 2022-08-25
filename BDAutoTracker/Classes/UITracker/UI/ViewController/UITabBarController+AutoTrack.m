//
//  UITabBarController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UITabBarController+AutoTrack.h"
#import "UIViewController+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"


/// UITabBarController 第一个展示的VC也会有回调

@implementation UITabBarController (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Index_Imp = nil;
    static IMP original_VC_Imp = nil;
    dispatch_once(&onceToken, ^{
        
        original_Index_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(setSelectedIndex:), ^(UITabBarController *_self, NSUInteger selected){
            if (original_Index_Imp) {
                UIViewController *last = _self.selectedViewController;
                ((void ( *)(id, SEL, NSUInteger))original_Index_Imp)(_self, @selector(setSelectedIndex:), selected);
                UIViewController *now = _self.selectedViewController;
                if (last && last != now) {
                    bd_ui_trackPage(last, now, NO);
                }
            }
        });

        original_VC_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(setSelectedViewController:), ^(UITabBarController *_self, UIViewController *selected){
            if (original_VC_Imp) {
                UIViewController *last = _self.selectedViewController;
                ((void ( *)(id, SEL, id))original_VC_Imp)(_self, @selector(setSelectedViewController:), selected);
                UIViewController *now = _self.selectedViewController;
                if (last && last != now) {
                    bd_ui_trackPage(last, now, NO);
                }
            }
        });
    });
}

@end
