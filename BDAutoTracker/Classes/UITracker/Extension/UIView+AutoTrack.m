//
//  UIView+Controller.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIView+AutoTrack.h"
#import "UIView+TrackInfo.h"
#import "UIResponder+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDTrackConstants.h"
#import <WebKit/WebKit.h>
#import "UIViewController+AutoTrack.h"


@implementation UIView (AutoTrack)

- (UIViewController *)bd_controller {
    UIResponder *nextResponder = [self nextResponder];
    while (nextResponder) {
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            UIViewController *parent = ((UIViewController *)nextResponder).parentViewController;

            if ([parent isKindOfClass:[UINavigationController class]]
                || [parent isKindOfClass:[UITabBarController class]]
                || ([parent isKindOfClass:[UIPageViewController class]] && !bd_ui_isMultiPage(parent))) {

                return (UIViewController*)nextResponder;
            }

            if (!parent) {
                return (UIViewController*)nextResponder;
            }
        }

        nextResponder = nextResponder.nextResponder;
    }
    
    return [UIViewController bd_topViewController];
}

- (NSArray<NSString *> *)bd_trackTitles {
    NSMutableArray<NSString *> *contents = [NSMutableArray array];
    NSString *title = [self bdAutoTrackViewContent] ?: [self bd_elementContent];
    if (title) {
        if (title.length > 200) {
            title = [title substringToIndex:199];
        }
        [contents addObject:title];
    }
    for (UIView *sub in self.subviews) {
        [contents addObjectsFromArray:[sub bd_trackTitles]];
    }

    return contents;
}

- (NSString *)bd_elementContent {
    return nil;
}

- (NSMutableDictionary *)bd_trackInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];

    NSArray<NSString *> *titles = [self bd_trackTitles];
    NSString *itemID = [self bdAutoTrackViewID];
    NSString *elementID = [self bdAutoTrackElementID];
    NSString *viewPath = [self bd_responderPath];
    NSString *elementType = [self bd_elementType];

    if (itemID.length) {
        [info setValue:itemID forKey:kBDAutoTrackEventViewID];
    }
    [info setValue:elementID ?: @""  forKey:kBDAutoTrackEventElementID];
    if (titles.count > 0) {
        [info setValue:titles forKey:kBDAutoTrackEventViewTitle];
    }
    NSDictionary *extra = [self bdAutoTrackExtraInfos];
    if ([extra isKindOfClass:[NSDictionary class]] && extra.count > 0) {
        [info setValue:extra forKey:kBDAutoTrackEventDataCustom];
    }

    [info setValue:viewPath forKey:kBDAutoTrackEventViewPath];
    NSArray *positions = [self bd_positions];
    if (positions.count) {
        [info setValue:positions forKey:kBDAutoTrackEventViewIndex];
    }
    
    [info setValue:elementType forKey:kBDAutoTrackEventElementType];
    
    // 自定义属性
    NSDictionary *properties = [self bdAutoTrackViewProperties];
    if ([properties isKindOfClass:[NSDictionary class]] && properties.count > 0) {
        [info addEntriesFromDictionary:properties];
    }
    
    return info;
}

- (NSMutableArray<NSIndexPath *> *)bd_indexPath {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:1];
    UIResponder *nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return indexPaths;
    }

    if ([nextResponder isKindOfClass:[UIView class]]) {
        UIView *next = (UIView *)nextResponder;
        [indexPaths addObjectsFromArray:[next bd_indexPath]];
    }

    return indexPaths;
}

- (NSArray<NSIndexPath *> *)bd_positions {
    NSArray<NSIndexPath *> *indexPath = [self bd_indexPath];
    NSMutableArray *positions = [NSMutableArray arrayWithCapacity:indexPath.count];
    if (indexPath.count) {

        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *pos = [NSString stringWithFormat:@"%zd-%zd",indexPath.section, indexPath.row];
            [positions addObject:pos];
        }];
    }
    return positions;
}

- (BOOL)bd_isWebViewComponent {
    if ([self isKindOfClass:[WKWebView class]]) {
        return YES;
    }

    NSString *path = [self bd_responderPath];
    if ([path containsString:@"WKScrollView"]) {
        return YES;
    }

    return NO;
}

- (NSString *)bd_elementType {
    return NSStringFromClass(self.class);
}

@end

#pragma mark some subClass implementation

@interface UILabel (AutoTrack)

@end

@implementation UILabel (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent = self.attributedText.string;
    if (elementContent.length < 1) {
        elementContent = self.text;
    }

    return elementContent;
}

@end

@interface UITextView (AutoTrack)

- (NSString *)bd_elementContent;

@end

@implementation UITextView (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent = self.attributedText.string;
    if (elementContent.length < 1) {
        elementContent = self.text;
    }
    
    return elementContent;
}

@end

@interface UISwitch (AutoTrack)


@end

@implementation UISwitch (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent = [NSString stringWithFormat:@"UISwitch state(%@)", self.isOn ? @"On" : @"Off"];
    return elementContent;
}

@end

@interface UIStepper (AutoTrack)

@end

@implementation UIStepper (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent = [NSString stringWithFormat:@"UIStepper value(%f)", self.value];
    return elementContent;
}

@end

@interface UISlider (AutoTrack)

@end

@implementation UISlider (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent = [NSString stringWithFormat:@"UISlider value(%f)", self.value];
    return elementContent;
}

@end

@interface UISegmentedControl (AutoTrack)

@end

@implementation UISegmentedControl (AutoTrack)

- (NSString *)bd_elementContent {
    NSString *elementContent;
    if (self.selectedSegmentIndex < 0 || self.selectedSegmentIndex >= self.numberOfSegments) {
        return nil;
    }
    NSString *selected = [self titleForSegmentAtIndex:self.selectedSegmentIndex];
    if (selected.length > 0) {
        elementContent = [NSString stringWithFormat:@"UISegmentedControl selected(%@)", selected];
    } else {
        elementContent = [NSString stringWithFormat:@"UISegmentedControl selectedIndex(%zd)", self.selectedSegmentIndex];
    }

    return elementContent;
}

@end

@interface UIDatePicker (AutoTrack)

@end

@implementation UIDatePicker (AutoTrack)

- (NSString *)bd_elementContent {
    return self.date.description;
}

- (NSArray<NSString *> *)bd_trackTitles {
    NSMutableArray<NSString *> *contents = [NSMutableArray array];
    NSString *title = [self bdAutoTrackViewContent] ?: [self bd_elementContent];
    if (title) {
        [contents addObject:title];
    }

    return contents;
}

@end

@interface UIPageControl (AutoTrack)

@end

@implementation UIPageControl (AutoTrack)

- (NSString *)bd_elementContent {
    return [NSString stringWithFormat:@"UIPageControl numberOfPages(%zd) currentPage(%zd)", self.numberOfPages, self.currentPage];
}

@end
