//
//  UIView+Picker.m
//  Applog
//
//  Created by bob on 2019/3/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIView+Picker.h"
#import "BDPickerConstants.h"
#import "BDPickerView.h"
#import <WebKit/WebKit.h>

#import "BDPickerDependency.h"

@implementation UIView (Picker)

- (UIView *)bd_webView {
    // web view
    UIView *webView = nil;
    UIView *superView = self;
    while (superView) {
        if ([superView isKindOfClass:[WKWebView class]]) {
            webView = superView;
            break;
        }

        superView = superView.superview;
    }

    return webView;
}

- (BOOL)bd_hasAction {
    BOOL hasAction = self.gestureRecognizers.count > 0;

    if (!hasAction && [self isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)self;
        hasAction = control.isEnabled && control.allTargets.count > 0;
    }
    /// list元素白名单
    if (!hasAction) {
        hasAction = [self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]];
    }

    return hasAction;
}

- (BOOL)bd_isListCoveredCell {
    UIView *nextResponder = [self superview];
    if ([nextResponder isKindOfClass:[UITableViewCell class]]
        || [nextResponder isKindOfClass:[UICollectionViewCell class]]) {
        if (self.gestureRecognizers.count < 2) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)bd_isSwitchCoveredView {
    UIView *nextResponder = [self superview];
    if ([nextResponder isKindOfClass:[UISwitch class]]) {
        return YES;
    }

    return NO;
}

- (UIView *)bd_pickedView {

    if ([self isKindOfClass:[UITableViewCell class]] || [self isKindOfClass:[UICollectionViewCell class]]) {
        return self;
    }

    /// web view
    if ([self bd_isWebViewComponent]) {
        return [self bd_webView];
    }

    /// 响应点击的control
    if ([self isKindOfClass:[UIControl class]]) {
        UIControl *selfControl = (UIControl *)self;
        if (selfControl.allTargets.count > 0 && selfControl.enabled) {
            return self;
        }
    }

    UIResponder *nextResponder = [self nextResponder];
    /// 上面已经不是view了
    if (![nextResponder isKindOfClass:[UIView class]]) {
        return self;
    }

    UIView *next = (UIView *)nextResponder;
    /// 大小不一样
    if (![self bd_isSizeCloseToParent:next.bounds]) {
        return self;
    }

    if ([self bd_isListCoveredCell]) {
        return next;
    }

    if ([self bd_isSwitchCoveredView]) {
        return next;
    }

    /// 本身无事件
    if (self.gestureRecognizers.count < 1) {
        return [next bd_pickedView];
    }

    return self;
}

- (BOOL)bd_isSizeCloseToParent:(CGRect)parent {
    CGRect frame = self.frame;

    if (CGRectEqualToRect(frame, parent)) {
        return YES;
    }

    if (fabs(frame.origin.x - parent.origin.x) > 2) {
        return NO;
    }

    if (fabs(frame.origin.y - parent.origin.y) > 2) {
        return NO;
    }

    if (fabs(frame.size.width - parent.size.width) > 2) {
        return NO;
    }

    if (fabs(frame.size.height - parent.size.height) > 2) {
        return NO;
    }

    return YES;
}

- (NSDictionary *)bd_pickerInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSArray<NSString *> *titles = [self bd_trackTitles];
    
    [info setValue:[self bd_responderPath] forKey:kBDPickerViewPath];
    if (titles.count > 0) {
        [info setValue:titles forKey:kBDPickerEventTexts];
    }

    NSArray *positions = [self bd_positions];
    if (positions.count) {
        [info setValue:positions forKey:kBDPickerEventIndex];

        NSMutableArray *fuzzyPositions = [NSMutableArray arrayWithCapacity:positions.count];
        [positions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [fuzzyPositions addObject: @"*"];
        }];
        [info setValue:fuzzyPositions forKey:kBDPickerEventFuzzyIndex];
    }
    [info setValue:@(NO) forKey:kBDPickerIsHTML];
    NSString *page = NSStringFromClass([[self bd_controller] class]);
    [info setValue:page forKey:kBDPickerPageKey];

    return info;
}

- (AppLogPickerView *)bd_pickerViewAt:(CGPoint)point {
    UIView *hitTestView = [self hitTest:point withEvent:nil];
    UIView *pickedView = [hitTestView bd_pickedView];

    if ([pickedView isKindOfClass:[WKWebView class]]) {
        
        AppLogPickerView * webPickedView = [pickedView bd_pickerView];
        if (webPickedView) {
            NSArray<AppLogPickerView *> *results = [webPickedView pickerViewAt:point];
            AppLogPickerView *pickerView = results.firstObject;
            for (AppLogPickerView *result in results) {
                if (result.zIndex > pickerView.zIndex) {
                    pickerView = result;
                }
            }

            return pickerView;
        }
    }

    return [[AppLogPickerView alloc] initWithView:pickedView];
}

- (AppLogPickerView *)bd_pickerView {
    // webView should return a BDPickerView
    return nil;
}

@end
