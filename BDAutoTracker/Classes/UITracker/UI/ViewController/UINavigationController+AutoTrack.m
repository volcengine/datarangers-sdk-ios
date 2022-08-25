//
//  UINavigationController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UINavigationController+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"


@implementation UINavigationController (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Pop_Imp = nil;
    static IMP original_Push_Imp = nil;
    static IMP original_PopTo_Imp = nil;
    static IMP original_PopToRoot_Imp = nil;
    dispatch_once(&onceToken, ^{
        original_Pop_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(popViewControllerAnimated:), ^UIViewController *(UINavigationController *_self, BOOL animated){
            if (original_Pop_Imp) {
                UIViewController *popVC = ((UIViewController * ( *)(id, SEL, BOOL))original_Pop_Imp)(_self, @selector(popViewControllerAnimated:), animated);
                UIViewController *topVC = _self.topViewController;
                if (popVC != topVC) {
                    bd_ui_trackPage(popVC, topVC, YES);
                }

                return popVC;
            }

            return nil;
        });

        original_Push_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(pushViewController:animated:), ^(UINavigationController *_self, UIViewController *viewController, BOOL animated){
            if (original_Push_Imp) {
                UIViewController *oldTopVC = _self.topViewController;
                if (oldTopVC) {
                    bd_ui_trackPage(oldTopVC, viewController, NO);
                }
                ((void ( *)(id, SEL, id, BOOL))original_Push_Imp)(_self, @selector(popViewControllerAnimated:), viewController, animated);
            }
        });

        original_PopTo_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(popToViewController:animated:), ^NSArray *(UINavigationController *_self, UIViewController *viewController, BOOL animated){
            if (original_PopTo_Imp) {
                UIViewController *oldTopVC = _self.topViewController;
                if (oldTopVC != viewController) {
                    bd_ui_trackPage(oldTopVC, viewController, YES);
                }
                NSArray* vcs = ((NSArray * ( *)(id, SEL, id, BOOL))original_PopTo_Imp)(_self, @selector(popToViewController:animated:),viewController, animated);

                return vcs;
            }
            return nil;
        });

        original_PopToRoot_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(popToRootViewControllerAnimated:), ^NSArray *(UINavigationController *_self, BOOL animated){
            if (original_PopToRoot_Imp) {
                UIViewController *oldTopVC = _self.topViewController;
                UIViewController *viewController = _self.viewControllers.firstObject;
                if (oldTopVC != viewController && _self.viewControllers.count > 1) {
                    bd_ui_trackPage(oldTopVC, viewController, YES);
                }
                NSArray* vcs = ((NSArray * ( *)(id, SEL, BOOL))original_PopToRoot_Imp)(_self, @selector(popToRootViewControllerAnimated:), animated);

                return vcs;
            }

            return nil;
        });
    });
}

@end
