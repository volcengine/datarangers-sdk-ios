//
//  BDPickerView.m

//
//  Created by bob on 2019/4/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDPickerView.h"
#import "UIView+Picker.h"
#import "UIViewController+Picker.h"
#import "BDPickerConstants.h"
#import <WebKit/WebKit.h>
#import "BDKeyWindowTracker.h"

#import "BDPickerDependency.h"
#import "NSDictionary+VETyped.h"

@interface AppLogPickerView ()

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, weak) UIView *view;

@property (nonatomic, copy) NSString *elementPath;
@property (nonatomic, assign) CGRect frameInWindow;
@property (nonatomic, assign) CGRect wrapperFrameInWindow;

@property (nonatomic, weak) AppLogPickerView *superView;
@property (nonatomic, strong) NSArray<AppLogPickerView *> *subViews;

@property (nonatomic, copy) NSDictionary *webPageInfo;
@property (nonatomic, copy) NSDictionary *webViewInfo;
@property (nonatomic, assign) CGRect webViewFrameInWindow;
@property (nonatomic, assign) BOOL isWebView;
@property (nonatomic, copy) NSDictionary *webViewRawInfo;
@property (nonatomic, assign) NSInteger zIndex;

#pragma mark - heat
@property (nonatomic, copy)   NSString      *pageKey;
@property (nonatomic, copy)   NSArray       *positions;

#pragma mark - Simulator
@property (nonatomic, copy) NSArray<NSString *> *texts;

@end

@implementation AppLogPickerView

+ (instancetype)pickerViewAt:(CGPoint)point {
    UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
    AppLogPickerView *pickedView = [keyWindow bd_pickerViewAt:point];

    return pickedView;
}

- (instancetype)initWithView:(UIView *)pickedView {
    
    if (!pickedView) {
        return nil;
    }

    self = [super init];
    if (self) {

        self.view = pickedView;
        self.frame = pickedView.frame;
        self.elementPath = [pickedView bd_responderPath];
        CGRect hitFrame = pickedView.bounds;
        if (pickedView.window) {
            hitFrame = [pickedView.window convertRect:hitFrame fromView:pickedView];
        }
        // keep in super's bounds
        if (pickedView.superview) {
            // superView might be a window
            UIView *superView = pickedView.superview;
            if (superView.window) {
                CGRect superFrame = [superView.window convertRect:superView.bounds fromView:superView];
                hitFrame = CGRectIntersection(hitFrame, superFrame);
            }
        }

        CGRect screnFrame =  [UIScreen mainScreen].bounds;
        hitFrame = CGRectIntersection(hitFrame, screnFrame);
        self.frameInWindow = hitFrame;
        self.wrapperFrameInWindow = CGRectIntersection(CGRectInset(hitFrame, -4, -4),screnFrame);
        self.positions = [pickedView bd_positions];
    }

    return self;
}

- (instancetype)initWithWebView:(UIView *)webview data:(NSDictionary *)data {
    self = [self initWithView:webview];
    if (self) {
        self.isWebView = YES;
        CGPoint offset = CGPointZero;
        UIEdgeInsets inset;
        for (UIView *subView in webview.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)subView;
                if (@available(iOS 11.0, *)) {
                    inset = scrollView.adjustedContentInset;
                    offset = CGPointMake(inset.left, inset.top);
                } else {
                    inset = scrollView.contentInset;
                    offset = CGPointMake(inset.left, inset.top);
                }

                break;
            }
        }

        self.webViewFrameInWindow = CGRectOffset(self.frameInWindow, offset.x, offset.y);
        NSString *page = [data vetyped_stringForKey:@"page"] ?: NSStringFromClass(webview.class);
        self.pageKey = page;
        self.webPageInfo =@{kBDPickerPageKey    :page,
                            kBDPickerIsHTML     :@(YES)
                            };

        NSArray *subViewsInfo = [data vetyped_arrayForKey:@"info"];

        if (subViewsInfo.count) {
            NSMutableArray<AppLogPickerView *> *subViews = [NSMutableArray arrayWithCapacity:subViewsInfo.count];

            for (NSDictionary *subViewInfo in subViewsInfo) {
                if ([subViewInfo isKindOfClass:[NSDictionary class]]) {
                    AppLogPickerView *subView = [[AppLogPickerView alloc] initWithData:subViewInfo
                                                                     superView:self
                                                                   webPageInfo:self.webPageInfo];
                    subView.pageKey = page;
                    [subViews addObject: subView];
                }
            }

            self.subViews = subViews;
        }
    }

    return self;
}

- (instancetype)initWithData:(NSDictionary *)data superView:(AppLogPickerView *)superView webPageInfo:(NSDictionary *)webPageInfo {
    self = [self init];
    if (self) {
        self.webViewRawInfo = data;
        self.isWebView = YES;
        self.webPageInfo = webPageInfo;
        self.superView = superView;

        NSMutableDictionary *webViewInfo = [NSMutableDictionary dictionaryWithCapacity:6];

        NSString *path = [data vetyped_stringForKey:kBDAutoTrackEventViewPath] ?: @"";
        self.elementPath = path;
        [webViewInfo setValue:path forKey:kBDPickerViewPath];
        NSArray<NSString *> *titles = [data vetyped_arrayForKey:@"texts"];
        if (titles.count) {
            [webViewInfo setValue:titles forKey:kBDPickerEventTexts];
        }
        self.texts = titles;
        NSArray *positions = [data vetyped_arrayForKey:kBDAutoTrackEventViewIndex];
        if (positions.count) {
            [webViewInfo setValue:positions forKey:kBDPickerEventIndex];
            self.positions = positions;
        }
        NSArray *fuzzyPositions = [data vetyped_arrayForKey:kBDPickerEventFuzzyIndex];
        if (fuzzyPositions.count) {
            [webViewInfo setValue:fuzzyPositions forKey:kBDPickerEventFuzzyIndex];
        }

        NSDictionary *frameDict = [data vetyped_dictionaryForKey:@"frame"];
        [webViewInfo setValue:frameDict forKey:@"frame"];

        CGRect webViewFrame = superView.webViewFrameInWindow;
        self.webViewFrameInWindow = webViewFrame;

        CGFloat x = [frameDict vetyped_doubleForKey:@"x"];
        CGFloat y = [frameDict vetyped_doubleForKey:@"y"];
        CGFloat width = [frameDict vetyped_doubleForKey:@"width"];
        CGFloat height = [frameDict vetyped_doubleForKey:@"height"];

        CGRect frameInWindow = CGRectMake(x + webViewFrame.origin.x, y  + webViewFrame.origin.y, width, height);
        self.frameInWindow = frameInWindow;
        self.wrapperFrameInWindow = CGRectIntersection(CGRectInset(frameInWindow, -4, -4),[UIScreen mainScreen].bounds);

        [webViewInfo setValue:@(YES) forKey:kBDPickerIsHTML];
        self.webViewInfo = webViewInfo;

        self.zIndex = [data vetyped_integerForKey:@"zIndex"];

        NSArray *subViewsInfo = [data vetyped_arrayForKey:@"children"];
        if (subViewsInfo.count) {
            NSMutableArray<AppLogPickerView *> *subViews = [NSMutableArray arrayWithCapacity:subViewsInfo.count];

            for (NSDictionary *subViewInfo in subViewsInfo) {
                if ([subViewInfo isKindOfClass:[NSDictionary class]]) {
                    AppLogPickerView *subView = [[AppLogPickerView alloc] initWithData:subViewInfo
                                                                     superView:self
                                                                   webPageInfo:self.webPageInfo];
                    [subViews addObject:subView];
                }
            }

            self.subViews = subViews;
        }

    }

    return self;
}

- (UIViewController *)controller {
    return [self.view bd_controller];
}

- (NSDictionary *)viewPickerInfo {
    return self.webViewInfo ?: [self.view bd_pickerInfo];
}

- (NSDictionary *)pagePickerInfo {
    return self.webPageInfo ?: [[self.view bd_controller] bd_pickerInfo];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AppLogPickerView class]]) {
        AppLogPickerView *that = (AppLogPickerView *)object;
        return [that.elementPath isEqualToString:self.elementPath] && CGRectEqualToRect(that.frameInWindow ,self.frameInWindow);
    }

    return NO;
}

- (NSArray<AppLogPickerView *> *)pickerViewAt:(CGPoint)point {
    NSMutableArray<AppLogPickerView *> *result = [NSMutableArray array];

    for (AppLogPickerView *subView in self.subViews) {
        [result addObjectsFromArray:[subView pickerViewAt:point]];
    }
    
    if (CGRectContainsPoint(self.frameInWindow, point)) {
        if (result.count < 1) {
            [result addObject:self];
            
            return result;
        } else {
            NSMutableArray<AppLogPickerView *> *higher = [NSMutableArray array];
            for (AppLogPickerView *subView in result) {
                if (subView.zIndex >= self.zIndex) {
                    [higher addObject:subView];
                }
            }
            if (higher.count < 1) {
                [higher addObject:self];
            }

            return higher;
        }
    }

    return result;
}

#pragma mark - simulator

- (void)fillFrameInfo:(NSMutableDictionary *)data {
    CGRect frame = self.frameInWindow;
    if (self.isWebView) {
        frame = self.webViewFrameInWindow;
    }
    NSInteger height = frame.size.height;
    NSInteger width = frame.size.width;
    NSInteger x = frame.origin.x;
    NSInteger y = frame.origin.y;
    NSDictionary *frameDict = @{@"x":@(x),
                                @"y":@(y),
                                @"height":@(height),
                                @"width":@(width)
                                };
    [data setValue:frameDict forKey:@"frame"];
}

- (NSMutableDictionary *)simulatorUploadInfoPageInfoWithDom:(NSArray *)dom {
    NSMutableDictionary *data = [NSMutableDictionary new];
    [self fillFrameInfo:data];
    if (!self.isWebView) {
        UIViewController *vc = [self.view bd_controller];
        if (vc) {
            NSString *page = NSStringFromClass(vc.class);
            [data setValue:page forKey:kBDPickerPageKey];
        }
        [data setValue:@(NO) forKey:@"is_html"];
    } else {
        [data setValue:@(YES) forKey:@"is_html"];
        [data setValue:self.pageKey ?: @"" forKey:kBDPickerPageKey];
        [data setValue:self.elementPath forKey:kBDAutoTrackEventViewPath];
    }

    [data setValue:dom forKey:@"dom"];

    return data;
}

- (NSMutableDictionary *)simulatorUploadInfoWithWebContainer:(NSMutableArray *)container {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    UIView *view = self.view;
    if (!view.hidden && view.alpha > 0.01
        && view.userInteractionEnabled) {
        [self fillCommonUploadInfo:data];
    }

    if ([view isKindOfClass:[WKWebView class]]) {
        [view bd_pickerView];
        [container addObject:view];
        [data setValue:@(YES) forKey:@"is_html"];
        return data;
    }

    if ([view bd_pickedView] != view) {
        [data setValue:@(YES) forKey:@"ignore"];
    }

    NSMutableArray *children = [NSMutableArray array];
    for (UIView *sub in view.subviews) {
        if (!sub.hidden && sub.alpha > 0.01
            && sub.userInteractionEnabled) {
            AppLogPickerView *subView = [[AppLogPickerView alloc] initWithView:sub] ;
            [children addObject:[subView simulatorUploadInfoWithWebContainer:container]];
        }
    }
    [data setValue:children forKey:@"children"];

    return data;
}

- (NSMutableArray *)webViewSimulatorUploadInfo {
    NSMutableArray *children = [NSMutableArray array];
    if (!self.isWebView) {
        return children;
    }

    if (self.subViews.count > 0) {
        for (AppLogPickerView *subView in self.subViews) {
            NSDictionary *webViewRawInfo = subView.webViewRawInfo;
            NSCAssert(webViewRawInfo, @"");
            if (webViewRawInfo) {
                [children addObject:webViewRawInfo];
            }
        }
    }
    
    return children;
}

- (void)fillCommonUploadInfo:(NSMutableDictionary *)data {
    [self fillFrameInfo:data];
    [data setValue:self.texts forKey:@"texts"];
    NSArray *positions = self.positions;
    if (positions.count > 0) {
        [data setValue:positions forKey:kBDAutoTrackEventViewIndex];
        NSMutableArray *fuzzyPositions = [NSMutableArray arrayWithCapacity:positions.count];
        [positions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [fuzzyPositions addObject: @"*"];
        }];
        [data setValue:fuzzyPositions forKey:kBDPickerEventFuzzyIndex];
    }
    [data setValue:self.elementPath forKey:kBDAutoTrackEventViewPath];
}

@end
