//
//  BDUIAutoTracker.m
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDUIAutoTracker.h"
#import "BDAutoTrack+Private.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackNotifications.h"

#import "UIViewController+AutoTrack.h"
#import "UITableViewCell+AutoTrack.h"
#import "UICollectionViewCell+AutoTrack.h"
#import "UIView+AutoTrack.h"
#import "NSObject+AutoTrack.h"
#import "UIBarButtonItem+AutoTrack.h"
#import "UIResponder+AutoTrack.h"
#import "BDTrackConstants.h"
#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackUtility.h"
#import "UIView+TrackInfo.h"
#import "BDAutoTrack+UITracker.h"
#import "NSDictionary+VETyped.h"

static NSDictionary *terminatePageHolder = nil;
static NSDictionary *alertVCInfo = nil;

void bd_ui_trackEvent(NSDictionary *event) {
    [BDAutoTrack trackUIEventWithData:event];
}

void bd_ui_trackEventWithData(NSString *event, NSDictionary *data) {
    bd_ui_trackEvent(@{kBDAutoTrackEventType:event ?: @"",
                     kBDAutoTrackEventData:data ?: @{}});
}

void bd_ui_trackLauchPage(void) {
    UIViewController *launch = [UIViewController bd_topViewController];
    NSMutableDictionary *data = [launch bd_pageTrackInfo];
    [data setValue:@"null(launch)" forKey:kBDAutoTrackEventReferPage];
    [data setValue:@"null(launch)" forKey:kBDAutoTrackEventReferPageID];
    [data setValue:@"null(launch)" forKey:kBDAutoTrackEventReferPageTitle];
    bd_ui_trackEventWithData(BDAutoTrackEventNamePage, data);
}

void bd_ui_storeTerminatePage(void) {
    UIViewController *terminate = [UIViewController bd_topViewController];
    NSMutableDictionary *data = [terminate bd_referPageTrackInfo];
    [data setValue:@"null(terminate)" forKey:kBDAutoTrackEventPage];
    [data setValue:@"null(terminate)" forKey:kBDAutoTrackEventPageID];
    [data setValue:@"null(terminate)" forKey:kBDAutoTrackEventPageTitle];
    /// keep safe
    terminatePageHolder = [data copy];
}

void bd_ui_trackTerminatePage(void) {
    if (terminatePageHolder.count > 0) {
        bd_ui_trackEventWithData(BDAutoTrackEventNamePage, terminatePageHolder);
        terminatePageHolder = nil;
    }
}

void bd_ui_trackAddRectPoint(CGRect rect,
                             CGPoint point,
                             NSMutableDictionary *result) {
    CGFloat scale = bd_device_screenScale();
    NSInteger height = scale * rect.size.height;
    NSInteger width = scale * rect.size.width;
    NSInteger x = scale * point.x;
    NSInteger y = scale * point.y;
    [result setValue:@(height) forKey:kBDAutoTrackViewHeight];
    [result setValue:@(width) forKey:kBDAutoTrackViewWidth];
    [result setValue:@(x) forKey:kBDAutoTrackViewX];
    [result setValue:@(y) forKey:kBDAutoTrackViewY];
}

#pragma mark - bd_ui_track


static void bd_ui_trackAddTouchInfo(UIView *view,
                                    UIEvent *event,
                                    NSMutableDictionary *result) {
    UITouch *touch = [[event touchesForView:view] anyObject];
    CGPoint point = [touch locationInView:view];
    bd_ui_trackAddRectPoint(view.frame, point, result);
}

NSMutableDictionary * bd_ui_trackPageInfo(UIView *view) {
    if (view.bd_AutoTrackInternalItem) {
        return nil;
    }
    UIViewController *topVC = [view bd_controller];
    if (topVC.bd_AutoTrackInternalItem) {
        return nil;
    }

    return [topVC bd_pageTrackInfo];
}

NSMutableDictionary * bd_ui_trackTopPageInfo() {
    UIViewController *topVC = [UIViewController bd_topViewController];
    if (topVC.bd_AutoTrackInternalItem) {
        return nil;
    }

    return [topVC bd_pageTrackInfo];
}


void bd_ui_trackAlertControllerAppear(UIAlertController *vc) {
    if (vc.bd_AutoTrackInternalItem
        || ![vc isKindOfClass:[UIAlertController class]]) {
        alertVCInfo = nil;
        return;
    }
    alertVCInfo = [vc bd_pageTrackInfo];
}

void bd_ui_trackAlertAction(NSString *action) {
    NSMutableDictionary *trackInfo = bd_ui_trackTopPageInfo();
    if (trackInfo && alertVCInfo && action) {
        NSString *page = [trackInfo vetyped_stringForKey:kBDAutoTrackEventPage];

        [trackInfo setValue:action forKey:kBDAutoTrackEventAlertAction];
        [trackInfo setValue:@[action] forKey:kBDAutoTrackEventViewTitle];
        NSString *viewPath = [NSString stringWithFormat:@"%@%@UIAlertController%@%@",page, kBDViewPathSeperator, kBDViewPathSeperator,action];
        [trackInfo setValue:viewPath forKey:kBDAutoTrackEventViewPath];
        [trackInfo addEntriesFromDictionary:alertVCInfo];
        bd_ui_trackEventWithData(BDAutoTrackEventNameAlert, trackInfo);
        alertVCInfo = nil;
    }
}

void bd_ui_trackControl(id control, UIEvent *event) {
    NSMutableDictionary *trackInfo = bd_ui_trackPageInfo(control);
    
    BOOL ignore = NO;
    if ([control respondsToSelector:@selector(bdAutoTrackIgnoreClick)]) {
        ignore = [control bdAutoTrackIgnoreClick];
        if (ignore) {
            return;
        }
    }
    if (trackInfo) {
        [trackInfo addEntriesFromDictionary:[control bd_trackInfo]];
        bd_ui_trackAddTouchInfo(control, event, trackInfo);
        bd_ui_trackEventWithData(BDAutoTrackEventNameClick, trackInfo);
    }
}

void bd_ui_trackNavigationButton(UIBarButtonItem *item, UIEvent *event) {
    NSMutableDictionary *trackInfo = bd_ui_trackTopPageInfo();
    if (trackInfo) {
        UIView *view = [[event allTouches] anyObject].view;
        if (view) {
            bd_ui_trackAddTouchInfo(view, event, trackInfo);
            [trackInfo addEntriesFromDictionary:[view bd_trackInfo]];
        }
        [item bd_fillCustomInfo:trackInfo];
        bd_ui_trackEventWithData(BDAutoTrackEventNameClick, trackInfo);
    }
}

void bd_ui_trackTableView(UITableView *tableView, NSIndexPath *indexPath) {
    NSMutableDictionary *trackInfo = bd_ui_trackPageInfo(tableView);
    if (trackInfo) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell == nil) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }

        [trackInfo addEntriesFromDictionary:[cell bd_trackInfo]];
        NSArray *pos = [cell bd_positions];
        [trackInfo setValue:pos forKey:kBDAutoTrackEventViewIndex];
        /// add location
        bd_ui_trackAddRectPoint(cell.frame, cell.bd_cellTouchPoint, trackInfo);
        bd_ui_trackEventWithData(BDAutoTrackEventNameListItemClick, trackInfo);
    }
}

void bd_ui_trackCollectionView(UICollectionView *collectionView, NSIndexPath *indexPath) {
    NSMutableDictionary *trackInfo = bd_ui_trackPageInfo(collectionView);
    if (trackInfo) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (cell == nil) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }

        [trackInfo addEntriesFromDictionary:[cell bd_trackInfo]];
        NSArray *pos = [cell bd_positions];
        [trackInfo setValue:pos forKey:kBDAutoTrackEventViewIndex];
        /// add location
        bd_ui_trackAddRectPoint(cell.frame, cell.bd_cellTouchPoint, trackInfo);
        bd_ui_trackEventWithData(BDAutoTrackEventNameListItemClick, trackInfo);
    }
}

void bd_ui_trackPageLeaveEvent(UIViewController *vc, NSDictionary *params) {
    NSMutableDictionary *pageInfo = [vc bd_pageTrackInfo];
    [pageInfo addEntriesFromDictionary:params];
    
    // 这个是 UIEvent 事件，受全埋点开关影响，正常情况应该走这个
    // bd_ui_trackEventWithData(BDAutoTrackEventNamePageLeave, data);
    
    // 这个是 UserEvent 事件，不受全埋点开关影响，和产品确认后，离开页面的事件暂时走这个（此处与 Android 一致）
    NSDictionary *data = @{
        kBDAutoTrackEventType:BDAutoTrackEventNamePageLeave,
        kBDAutoTrackEventData:pageInfo
    };
    [BDAutoTrack trackPageLeaveEventWithData:data];
}

void bd_ui_trackPageEvent(UIViewController *from, UIViewController *to, BOOL isBack) {
    if (!from || !to) {
        return;
    }
    
    
    
    NSMutableDictionary *data = [to bd_pageTrackInfo];
    [data addEntriesFromDictionary:[from bd_referPageTrackInfo]];
    [data setValue:(isBack ? @1 : @0) forKey:kBDAutoTrackEventPageIsBack];
    bd_ui_trackEventWithData(BDAutoTrackEventNamePage, data);
    /// postNotification for Heimdallr
    NSDictionary *userInfo = @{kBDAutoTrackViewControllerFormer:NSStringFromClass(from.class),
                               kBDAutoTrackViewControllerAfter:NSStringFromClass(to.class),
                               kBDAutoTrackSwitchIsBack:(isBack ? @1 : @0)
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackVCSwitchEventNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

void bd_ui_trackPage(UIViewController *from, UIViewController *to, BOOL isBack) {
    UIViewController *fromTop = [from bd_topViewController:YES];
    UIViewController *toTop = [to bd_topViewController:YES];

    if (fromTop.bd_AutoTrackInternalItem || toTop.bd_AutoTrackInternalItem) {
        return;
    }

    bd_ui_trackPageEvent(fromTop, toTop, isBack);
}

void bd_ui_trackPages(NSArray<UIViewController *> *froms, NSArray<UIViewController *> *tos) {
    UIViewController *fromTop = [froms lastObject];
    UIViewController *toTop = [tos lastObject];

    if (fromTop.bd_AutoTrackInternalItem || toTop.bd_AutoTrackInternalItem) {
        return;
    }

    bd_ui_trackPage(fromTop, toTop, NO);
}

void bd_ui_trackWebEvent(id event) {
    if ([event isKindOfClass:[NSArray class]]) {
        NSArray *eventsArray = (NSArray *)event;
        for (NSDictionary *e in eventsArray) {
            if ([e isKindOfClass:[NSDictionary class]]) {
                bd_ui_trackEvent(e);
            }
        }
    } else if ([event isKindOfClass:[NSDictionary class]]) {
        bd_ui_trackEvent(event);
    } else if ([event isKindOfClass:[NSString class]]) {
        id object = bd_JSONValueForString(event);
        if (object && ![object isKindOfClass:[NSString class]]) {
            bd_ui_trackWebEvent(object);
        }
    }
}

BOOL bd_ui_isMultiPage(UIViewController *page) {
    if ([page isKindOfClass:[UIPageViewController class]]) {
        UIPageViewController *parent = (UIPageViewController *)page;
        return parent.viewControllers.count > 1;
    }

    return NO;
}
