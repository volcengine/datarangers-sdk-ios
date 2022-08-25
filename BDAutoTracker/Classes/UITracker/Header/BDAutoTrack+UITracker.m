//
//  BDAutoTrack+UITracker.m
//  RangersAppLog
//
//  Created by bytedance on 1/27/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+UITracker.h"
#import "BDAutoTrack+Private.h"
#import "UIViewController+TrackInfo.h"
#import "UIView+TrackInfo.h"
#import "UIViewController+AutoTrack.h"
#import "UIView+AutoTrack.h"
#import "BDTrackConstants.h"
#import "BDUIAutoTracker.h"
#import "BDCommonDefine.h"

@implementation BDAutoTrack (UITracker)


- (void)ignoreAutoTrackPage:(NSArray<Class> *)classes
{
    @try {
        [self.syncLocker lock];
        for (Class clz in classes) {
            [self.ignoredPageClasses addObject: NSStringFromClass(clz)];
        }
    }@finally {
        [self.syncLocker unlock];
    }
    
}

- (BOOL)isPageIgnored:(id)controller
{
    @try {
        [self.syncLocker lock];
        NSString *className;
        if ([controller isKindOfClass:[NSString class]]) {
            className = controller;
        } else {
            className = NSStringFromClass([controller class]);
        }
        return [self.ignoredPageClasses containsObject:className];
        
    }@finally {
        [self.syncLocker unlock];
    }
}

- (void)ignoreAutoTrackClick:(NSArray<Class> *)classes;
{
    @try {
        [self.syncLocker lock];
        
        for (Class clz in classes) {
            [self.ignoredClickViewClasses addObject: NSStringFromClass(clz)];
        }
    }@finally {
        [self.syncLocker unlock];
    }
}

- (BOOL)isClickIgnored:(id)view
{
    @try {
        [self.syncLocker lock];
        NSString *className;
        if ([view isKindOfClass:[NSString class]]) {
            className = view;
        } else {
            className = NSStringFromClass([view class]);
        }
        return [self.ignoredClickViewClasses containsObject:className];
    }@finally {
        [self.syncLocker unlock];
    }
}


- (BOOL)trackPage:(id<BDAutoTrackable>)page
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if ([page isKindOfClass:[UIViewController class]] &&
        [page respondsToSelector:@selector(bd_pageTrackInfo)]) {
        UIViewController *controller = (UIViewController *)page;
        NSDictionary *pageInfo = [controller performSelector:@selector(bd_pageTrackInfo)];
        [info addEntriesFromDictionary:pageInfo?:@{}];
    }
    
    if ([page respondsToSelector:@selector(bdAutoTrackParameters)]) {
        NSDictionary *properties = [page bdAutoTrackParameters];
        if (properties && [NSJSONSerialization isValidJSONObject:properties]) {
            [info addEntriesFromDictionary:properties];
        }
    }
    
    return [self eventV3:BDAutoTrackEventNamePage params:info];
}


- (BOOL)trackPage:(id)page withParameters:(nullable NSDictionary<NSString *,id> *)params
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if ([page isKindOfClass:[UIViewController class]] &&
        [page respondsToSelector:@selector(bd_pageTrackInfo)]) {
        UIViewController *controller = (UIViewController *)page;
        NSDictionary *pageInfo = [controller performSelector:@selector(bd_pageTrackInfo)];
        [info addEntriesFromDictionary:pageInfo?:@{}];
    }
    
    if ([page respondsToSelector:@selector(bdAutoTrackParameters)]) {
        NSDictionary *properties = [page bdAutoTrackParameters];
        if (properties && [NSJSONSerialization isValidJSONObject:properties]) {
            [info addEntriesFromDictionary:properties];
        }
    }
    if ([params isKindOfClass:[NSDictionary class]] && [NSJSONSerialization isValidJSONObject:params]) {
        [info addEntriesFromDictionary:params];
    }
    return [self eventV3:BDAutoTrackEventNamePage params:info];
}



- (BOOL)trackClick:(id<BDAutoTrackable>)control
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    if ([control isKindOfClass:[UIView class]]) {
        UIView *v = (UIView *)control;
        NSDictionary * pageInfo = bd_ui_trackPageInfo(v) ?: bd_ui_trackTopPageInfo();
        [info addEntriesFromDictionary:pageInfo];
        
        if ([v respondsToSelector:@selector(bd_trackInfo)]) {
            NSDictionary *controlInfo = [v bd_trackInfo];
            [info addEntriesFromDictionary:controlInfo];
        }
    }
    
    if ([control respondsToSelector:@selector(bdAutoTrackParameters)]) {
        NSDictionary *properties = [control bdAutoTrackParameters];
        if (properties && [NSJSONSerialization isValidJSONObject:properties]) {
            [info addEntriesFromDictionary:properties];
        }
    }
    return [self eventV3:BDAutoTrackEventNameClick params:info];
}

- (BOOL)trackClick:(id<BDAutoTrackable>)control withParameters:(nullable NSDictionary<NSString *,id> *)params
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    if ([control isKindOfClass:[UIView class]]) {
        UIView *v = (UIView *)control;
        NSDictionary * pageInfo = bd_ui_trackPageInfo(v) ?: bd_ui_trackTopPageInfo();
        [info addEntriesFromDictionary:pageInfo];
        
        if ([v respondsToSelector:@selector(bd_trackInfo)]) {
            NSDictionary *controlInfo = [v bd_trackInfo];
            [info addEntriesFromDictionary:controlInfo];
        }
    }
    
    if ([control respondsToSelector:@selector(bdAutoTrackParameters)]) {
        NSDictionary *properties = [control bdAutoTrackParameters];
        if (properties && [NSJSONSerialization isValidJSONObject:properties]) {
            [info addEntriesFromDictionary:properties];
        }
    }
    if ([params isKindOfClass:[NSDictionary class]] && [NSJSONSerialization isValidJSONObject:params]) {
        [info addEntriesFromDictionary:params];
    }
    return [self eventV3:BDAutoTrackEventNameClick params:info];
}


@end
