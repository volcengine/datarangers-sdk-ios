//
//  UIView+BDAutoTrackExposure.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/2.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIView+BDAutoTrackExposure.h"
#import "BDAUtoTrack.h"
#import "BDAutoTrackExposure.h"
#import "BDTrackerObjectBindContext.h"
#import "BDAutoTrackExposureManager.h"
#import "BDAutoTrackSwizzle.h"
#import "RangersLog.h"
#import "BDAutoTrackExposure.h"
#import "UIView+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackExposurePrivate.h"

static NSString *kSubContextExposure = @"exposure_ctx";


@interface BDAutoTrackExposureDetectionItem : NSObject

@property (nonatomic, weak) UIView* view;
@property (nonatomic, weak) BDAutoTrack* tracker;
@property (nonatomic, assign) BOOL exposed;
@property (nonatomic, strong) BDViewExposureData *event;

- (void)detectIfExposed:(CGRect)rect;

@end

@implementation BDAutoTrackExposureDetectionItem

- (void)detectIfExposed:(CGRect)rect
{
    BOOL exposed = NO;
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {
        exposed = NO;
    } else {
        
        CGFloat areaRadio = self.event.config.areaRatio;
        if (areaRadio == 0.0) {
            exposed = YES;
        } else if (round(rect.size.width * rect.size.height) >=
                   round(self.view.bounds.size.width * self.view.bounds.size.height) * areaRadio) {
            exposed = YES;
        }
    }
    self.exposed = exposed;
    
}

- (void)setExposed:(BOOL)exposed
{
    BOOL currentState = _exposed;
    _exposed = exposed;
    if (!currentState && exposed) {
        [self enterScreen];
        [self.view bdexposure_markIfExposed];
    }
    if (currentState && !exposed) {
        [self leaveScreen];
        [self.view bdexposure_markIfExposed];
    }
   
}

- (void)enterScreen
{
    RL_DEBUG(self.tracker.appID, @"[Exposure][%@] enter screen", self.view.bdtracker_pointerId);
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:bd_ui_trackPageInfo(self.view)];
    [properties addEntriesFromDictionary:[self.view bd_trackInfo]?:@{}];
    [properties addEntriesFromDictionary:self.event.properties?:@{}];
    if ([self.event.eventName length] > 0) {
        [self.tracker eventV3:self.event.eventName params:properties];
    } else {
        [self.tracker eventV3:@"bav2b_exposure" params:properties];
    }
}

- (void)leaveScreen
{
    RL_DEBUG(self.tracker.appID, @"[Exposure][%@] leave screen", self.view.bdtracker_pointerId);
}

@end



@interface BDAutoTrackExposureContext : NSObject

@property (nonatomic, weak) id hostView;

#pragma mark - debug
@property (nonatomic) CGColorRef borderColorRef;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) BOOL observableMarked;
@property (nonatomic, strong) CALayer *maskLayer;

@property (nonatomic, readonly) BOOL exposed;

@property (nonatomic, assign) BOOL observable;

@property (nonatomic, strong) NSMutableArray<BDAutoTrackExposureDetectionItem *> *items;

- (void)markInvisible;

- (void)detectIfExposed:(CGRect)rect;


@end




@implementation BDAutoTrackExposureContext {
}

- (instancetype)init
{
    if (self = [super init]) {
        self.items = [NSMutableArray new];
    }
    return self;
}


- (BOOL)observable
{
    return [self.items count] > 0;
}


- (void)addTracker:(BDAutoTrack *)tracker withEvent:(BDViewExposureData *)event
{
    
    BDViewExposureConfig *global = tracker.config.exposureConfig;
    [event.config apply:global];
    
    __block BOOL isUpdate = NO;
    __block BDAutoTrackExposureDetectionItem* existingItem;
    [self.items enumerateObjectsUsingBlock:^(BDAutoTrackExposureDetectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BDViewExposureData *original = obj.event;
        obj.event = event;
        if (obj.tracker == tracker) {
            existingItem = obj;
            if ([original isEqual:event]) {
                isUpdate = YES;
            }
            *stop = YES;
        }
    }];
    if (isUpdate) {
        return;
    }
    
    if (existingItem) {
        existingItem.exposed = NO;
        [self.items removeObject:existingItem];
    }
    
    BDAutoTrackExposureDetectionItem *item = [[BDAutoTrackExposureDetectionItem alloc] init];
    item.tracker = tracker;
    item.view = self.hostView;
    item.event = event;
    item.exposed = NO;
    [self.items addObject:item];
    
    RL_DEBUG(tracker.appID, @"[Exposure][%@] observe. ( %@ )", [item.view bdtracker_pointerId], item.event );

}

- (void)removeTracker:(BDAutoTrack *)tracker
{
    __block BDAutoTrackExposureDetectionItem *existItem;
    [self.items enumerateObjectsUsingBlock:^(BDAutoTrackExposureDetectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tracker == tracker) {
            existItem = obj;
            *stop = YES;
        }
    }];
    if (existItem) {
        existItem.exposed = NO;
        [self.items removeObject:existItem];
    }
   
}

- (void)detectIfExposed:(CGRect)rect
{
    [self.items enumerateObjectsUsingBlock:^(BDAutoTrackExposureDetectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj detectIfExposed:rect];
    }];
}

- (void)markInvisible
{
    [self.items enumerateObjectsUsingBlock:^(BDAutoTrackExposureDetectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.exposed = NO;
    }];
}

- (BOOL)exposed
{
    __block BOOL exposed = NO;
    [self.items enumerateObjectsUsingBlock:^(BDAutoTrackExposureDetectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.exposed) {
            exposed = YES;
            *stop = YES;
        }
    }];
    return exposed;
}

@end





@implementation UIView (BDAutoTrackExposure)

- (BDAutoTrackExposureContext *)bdexposure_context
{
    id ctx = [self.bdtracker_context valueForKey:kSubContextExposure];
    if (!ctx) {
        ctx = [BDAutoTrackExposureContext new];
        [self.bdtracker_context setValue:ctx forKey:kSubContextExposure];
        [ctx setHostView:self];
    }
    return ctx;
}


- (void)bdexposure_add:(BDAutoTrack *)tracker
                  with:(BDViewExposureData *)event
{
    @synchronized (self) {
        [[self bdexposure_context] addTracker:tracker withEvent:event];
        [self bdexposure_markIfTrackable];
    }
   
}

- (void)bdexposure_clear:(BDAutoTrack *)tracker
{
    @synchronized (self) {
        [[self bdexposure_context] removeTracker:tracker];
        [self bdexposure_markIfTrackable];
    }
    
}

- (BOOL)bdexposure_isObserved
{
    return [self bdexposure_context].observable;
}

#pragma mark - visual debugging
- (void)bdexposure_markIfExposed
{
    if (![BDAutoTrackExposureManager sharedInstance].debugON) {
        return;
    }
    [[self bdexposure_context].maskLayer removeFromSuperlayer];
    if ([self bdexposure_context].exposed) {
        if (![self bdexposure_context].maskLayer) {
            CALayer *maskLayer = [CALayer layer];
            maskLayer.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.4].CGColor;
            [self bdexposure_context].maskLayer = maskLayer;
        }
        [self bdexposure_context].maskLayer.frame = self.bounds;
        [self.layer addSublayer:[self bdexposure_context].maskLayer];
    }
}

- (void)bdexposure_markIfTrackable
{
    if (![BDAutoTrackExposureManager sharedInstance].debugON) {
        return;
    }
    if ([self bdexposure_context].observable) {
        if (![self bdexposure_context].observableMarked) {
            [self bdexposure_context].borderColorRef = self.layer.borderColor;
            [self bdexposure_context].borderWidth = self.layer.borderWidth;
            self.layer.borderColor = [UIColor redColor].CGColor;
            self.layer.borderWidth = 2.0f;
            [self bdexposure_context].observableMarked = YES;
        }
    } else {
        if ([self bdexposure_context].observableMarked) {
            self.layer.borderColor = [self bdexposure_context].borderColorRef;
            self.layer.borderWidth = [self bdexposure_context].borderWidth;
            [self bdexposure_context].observableMarked = NO;
        }
    }
    
}


#pragma mark -

- (void)bdexposure_detectVisible:(CGRect)visibleRect
{
    if (![self bdexposure_containsObservedView]) {
        return;
    }
    BOOL visible = NO;
    CGRect exposedRect = CGRectZero;
    @try {
        
        if (![self isKindOfClass:[UIWindow class]] && !self.window) {
            visible = NO;
            return;
        }
        
        if (self.hidden
            || self.alpha == 0.0f
            || CGRectIsNull(self.frame)) {
            visible = NO;
            return;
        }
        
        if ([self isKindOfClass:[UIWindow class]]) {
            exposedRect = visibleRect;
        } else {
            CGRect rect = [self.window convertRect:self.frame fromView:self.superview];
            exposedRect = CGRectIntersection(visibleRect, rect);
        }
        
        if (!CGRectIsEmpty(exposedRect)) {
            visible = YES;
            
            if ([self bdexposure_isObserved]) {
                [[self bdexposure_context] detectIfExposed:exposedRect];
            }
        }
        
    } @finally {
        if (!visible) {
            [self bdexposure_makeDescendantInvisible];
        } else {
            [[self subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj bdexposure_detectVisible:exposedRect];
            }];
        }
    }
}

- (void)bdexposure_makeDescendantInvisible
{
    [[[BDAutoTrackExposureManager sharedInstance] observedViews] enumerateObjectsUsingBlock:^(UIView*  _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([view isDescendantOfView:self]) {
            [view.bdexposure_context markInvisible];
        }
    }];
}

- (BOOL)bdexposure_containsObservedView
{
    __block BOOL contains = NO;
    [[[BDAutoTrackExposureManager sharedInstance] observedViews] enumerateObjectsUsingBlock:^(UIView*  _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([view isDescendantOfView:self]) {
            *stop = YES;
            contains = YES;
        }
    }];
    return contains;
}

- (void)bdexposure_markInvisible
{
    [self.bdexposure_context markInvisible];
}


@end



