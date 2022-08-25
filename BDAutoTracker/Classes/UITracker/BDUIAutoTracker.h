//
//  BDUIAutoTracker.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

/// UI 自动埋点 启动
NS_ASSUME_NONNULL_BEGIN

@class UIView, UIControl, UITableView, UICollectionView, UIViewController, UIAlertController;

FOUNDATION_EXTERN void bd_ui_trackEvent(NSDictionary *event);
FOUNDATION_EXTERN void bd_ui_trackEventWithData(NSString *event, NSDictionary *data);
FOUNDATION_EXTERN void bd_ui_trackLauchPage(void);
FOUNDATION_EXTERN void bd_ui_storeTerminatePage(void);
FOUNDATION_EXTERN void bd_ui_trackTerminatePage(void);
FOUNDATION_EXTERN void bd_ui_trackAddRectPoint(CGRect rect,
                                               CGPoint point,
                                               NSMutableDictionary *result);

#pragma mark - specific event
FOUNDATION_EXTERN NSMutableDictionary * bd_ui_trackTopPageInfo(void);
FOUNDATION_EXTERN NSMutableDictionary * bd_ui_trackPageInfo(UIView *view);

FOUNDATION_EXTERN void bd_ui_trackAlertControllerAppear(UIAlertController *vc);
FOUNDATION_EXTERN void bd_ui_trackAlertAction(NSString *action);
FOUNDATION_EXTERN void bd_ui_trackControl(UIControl *control, UIEvent *event);
FOUNDATION_EXTERN void bd_ui_trackNavigationButton(UIBarButtonItem *item, UIEvent *event);
FOUNDATION_EXTERN void bd_ui_trackTableView(UITableView *tableView, NSIndexPath *indexPath);
FOUNDATION_EXTERN void bd_ui_trackCollectionView(UICollectionView *collectionView, NSIndexPath *indexPath);
FOUNDATION_EXTERN void bd_ui_trackPageEvent(UIViewController *from, UIViewController *to, BOOL isBack);
FOUNDATION_EXTERN void bd_ui_trackPageLeaveEvent(UIViewController *vc, NSDictionary *params);
FOUNDATION_EXTERN void bd_ui_trackPage(UIViewController *from, UIViewController *to, BOOL isBack);
FOUNDATION_EXTERN void bd_ui_trackPages(NSArray<UIViewController *> *froms, NSArray<UIViewController *> *tos);
FOUNDATION_EXTERN BOOL bd_ui_isMultiPage(UIViewController *page);

#pragma mark - web event

FOUNDATION_EXTERN void bd_ui_trackWebEvent(id _Nullable event);

NS_ASSUME_NONNULL_END
