//
//  UIViewController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIViewController+AutoTrack.h"
#import "UIViewController+TrackInfo.h"
#import "BDTrackConstants.h"
#import "BDKeyWindowTracker.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackPageLeave.h"


@implementation UIViewController (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_DidAppear_Imp = nil;
    static IMP original_DidDisappear_Imp = nil;
    static IMP original_Present_Imp = nil;
    static IMP original_Dismiss_Imp = nil;
    dispatch_once(&onceToken, ^{

        original_DidAppear_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(viewDidAppear:), ^(UIViewController *_self, BOOL animated){
            if (original_DidAppear_Imp) {
                if ([_self isKindOfClass:[UIAlertController class]]) {
                    bd_ui_trackAlertControllerAppear((UIAlertController *)_self);
                } else {
                    [[BDAutoTrackPageLeave shared] enterPage:_self];
                }
                ((void ( *)(id, SEL, BOOL))original_DidAppear_Imp)(_self, @selector(viewDidAppear:), animated);
            }
        });
        
        original_DidDisappear_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(viewDidDisappear:), ^(UIViewController *_self, BOOL animated){
            if (original_DidDisappear_Imp) {
                if (![_self isKindOfClass:[UIAlertController class]]) {
                    [[BDAutoTrackPageLeave shared] leavePage:_self];
                }
                ((void ( *)(id, SEL, BOOL))original_DidDisappear_Imp)(_self, @selector(viewDidDisappear:), animated);
            }
        });

        original_Present_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(presentViewController:animated:completion:), ^(UIViewController *_self, UIViewController *viewControllerToPresent, BOOL animated, dispatch_block_t completion){
            if (original_Present_Imp) {
                if (![viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
                    UIViewController *presenting = [_self bd_topViewController:YES];
                    bd_ui_trackPage(presenting, viewControllerToPresent, NO);
                }

                ((void ( *)(id, SEL, UIViewController *, BOOL, dispatch_block_t))original_Present_Imp)(_self, @selector(presentViewController:animated:completion:), viewControllerToPresent, animated, completion);
            }
        });

        original_Dismiss_Imp = bd_swizzle_instance_methodWithBlock([self class], @selector(dismissViewControllerAnimated:completion:), ^(UIViewController *_self, BOOL animated, dispatch_block_t completion){
            if (original_Dismiss_Imp) {

                UIViewController *presented = [_self bd_topViewController:YES];
                ((void ( *)(id, SEL, BOOL, dispatch_block_t))original_Dismiss_Imp)(_self, @selector(dismissViewControllerAnimated:completion:), animated, completion);

                if (![presented isKindOfClass:[UIAlertController class]]) {
                    UIViewController *current;
                    if (_self.presentedViewController) {
                        current = [_self bd_topViewController:NO];
                    } else {
                        current = [[_self presentingViewController] bd_topViewController:NO];
                    }
                    
                    if (current != presented) {
                        bd_ui_trackPage(presented, current, YES);
                    }
                }
            }
        });
    });
}

+ (UIViewController *)bd_topViewController {
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    UIViewController *topViewController = keyWindow.rootViewController;
    
    return [topViewController bd_topViewController:YES];
}

- (UIViewController *)bd_topViewController:(BOOL)showPresented {

    if (self.presentedViewController && showPresented) {
        return [self.presentedViewController bd_topViewController:YES];
    }

    if ([self isKindOfClass:[UINavigationController class]]) {
        return [[(UINavigationController *)self topViewController] bd_topViewController:showPresented];
    }

    if ([self isKindOfClass:[UITabBarController class]]) {
        return [[(UITabBarController *)self selectedViewController] bd_topViewController:showPresented];
    }

    /// UIPageViewController 且不展示多页
    if ([self isKindOfClass:[UIPageViewController class]] && !bd_ui_isMultiPage(self)) {
        ///  lastObject
        return [[[(UIPageViewController *)self viewControllers] lastObject] bd_topViewController:showPresented];
    }

    return self;
}

- (NSString *)bd_pageTrackTitle {
    NSString *pageTitle = [self bdAutoTrackPageTitle];
    if (pageTitle) {
        return pageTitle;
    }

    if (self.navigationItem.title.length > 0) {
        return self.navigationItem.title;
    }

    if (self.tabBarItem.title.length > 0) {
        return self.tabBarItem.title;
    }

    if (self.navigationController) {
        return NSStringFromClass([self class]);
    }

    if (self.parentViewController) {
        return [self.parentViewController bd_pageTrackTitle];
    }

    return NSStringFromClass([self class]);
}

- (NSMutableDictionary *)bd_pageTrackInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSString *pageTitle = [self bd_pageTrackTitle];
    NSString *pageID = [self bdAutoTrackPageID];
    NSString *pagePath = [self bdAutoTrackPagePath];
    NSString *page = NSStringFromClass([self class]);

    NSDictionary *extra = [self bdAutoTrackExtraInfos];
    if (pageID.length) {
        [info setValue:pageID forKey:kBDAutoTrackEventPageID];
    }
    if (pagePath.length) {
        [info setValue:pagePath forKey:kBDAutoTrackEventPagePath];
    }
    if ([extra isKindOfClass:[NSDictionary class]] && extra.count > 0) {
        [info setValue:extra forKey:[@"page_%@" stringByAppendingString:kBDAutoTrackEventDataCustom]];
    }

    [info setValue:page forKey:kBDAutoTrackEventPage];
    [info setValue:pageTitle forKey:kBDAutoTrackEventPageTitle];
    
    // 自定义属性
    NSDictionary *properties = [self bdAutoTrackPageProperties];
    if ([properties isKindOfClass:[NSDictionary class]] && properties.count > 0) {
        [info addEntriesFromDictionary:properties];
    }

    return info;
}

- (NSMutableDictionary *)bd_referPageTrackInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSString *pageTitle = [self bd_pageTrackTitle];
    NSString *pageID = [self bdAutoTrackPageID];
    NSString *pagePath = [self bdAutoTrackPagePath];
    NSString *page = NSStringFromClass([self class]);

    NSDictionary<NSString*, NSString *> *extra = [self bdAutoTrackExtraInfos];
    if (pageID.length) {
        [info setValue:pageID forKey:kBDAutoTrackEventReferPageID];
    }
    if ([extra isKindOfClass:[NSDictionary class]] && extra.count>0) {
        [info setValue:extra forKey:[ @"refer_page_%@" stringByAppendingString:kBDAutoTrackEventDataCustom]];
    }

    [info setValue:page forKey:kBDAutoTrackEventReferPage];
    [info setValue:pageTitle ?: @"" forKey:kBDAutoTrackEventReferPageTitle];
    [info setValue:pagePath ?: @"" forKey:kBDAutoTrackEventReferPagePath];

    return info;
}

@end
