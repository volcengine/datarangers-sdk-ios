//
//  UIPageViewController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIPageViewController+AutoTrack.h"
#import <objc/runtime.h>
#import "UIViewController+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"

/// UIPageViewController 第一个展示的VC 不会有回调

@interface BDPageDelegateDecorator: NSObject

@end

@implementation BDPageDelegateDecorator

- (BOOL)bd_isPageTrackerDecorator {
    return YES;
}

@end

@implementation UIPageViewController (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BDAutoTrackSwizzle *swizzle = [BDAutoTrackSwizzle new];
        
        swizzle.originIMP = bd_swizzle_instance_methodWithBlock([self class], @selector(setDelegate:), ^(UIPageViewController *_self, id delegate){
            if (swizzle.originIMP) {
                if (delegate == nil) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), nil);
                    return;
                }
                if ([delegate respondsToSelector:@selector(bd_isPageTrackerDecorator)]) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
                    return;
                }
                
                Class delegateClass = object_getClass(delegate);
                SEL selector = @selector(pageViewController:didFinishAnimating:previousViewControllers:transitionCompleted:);
                if (bd_swizzle_has_selector(delegate, selector))  {
                    bd_swizzle_instance_addMethod(delegateClass,
                                                  @selector(bd_isPageTrackerDecorator),
                                                  BDPageDelegateDecorator.class);
                    BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                    
                    id delegateBlock = ^void (id delegateSelf, UIPageViewController *pageViewController, BOOL finished, NSArray<UIViewController *> *previousViewControllers, BOOL completed) {
                        if (completed) {
                            NSArray<UIViewController *> *currents = [pageViewController viewControllers];
                            bd_ui_trackPages(previousViewControllers, currents);
                        }
                        
                        if (delegateSwizzle.originIMP) {
                            return ((void ( *)(id, SEL, UIPageViewController *, BOOL,NSArray *, BOOL ))delegateSwizzle.originIMP)(delegateSelf, selector, pageViewController, finished, previousViewControllers, completed);
                        }
                    };
                    delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass, selector, delegateBlock);
                }
                
                ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
            }
        });
    });
}

@end
