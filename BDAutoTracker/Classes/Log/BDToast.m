//
//  BDToast.m
//  RangersAppLog
//
//  Created by 陈奕 on 2019/9/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDToast.h"
#import <objc/runtime.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>


static UILabel *bd_picker_toastView(NSString *message) {
    
    UILabel *messageView = [UILabel new];
    messageView.layer.cornerRadius = 8;
    messageView.layer.masksToBounds = YES;
    messageView.backgroundColor = [UIColor blackColor];
    messageView.numberOfLines = 0;
    messageView.textAlignment = NSTextAlignmentCenter;
    messageView.textColor = [UIColor whiteColor];
    UIFont *font = [UIFont systemFontOfSize:15];
    messageView.font = font;
    messageView.alpha = 0.8;

    CGRect rect = [message boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:font}
                                        context:nil];
    CGFloat width = rect.size.width + 20;
    CGFloat height = rect.size.height + 20;
    messageView.frame = CGRectMake(0, 0, width, height);
    messageView.text = message;

    return messageView;
}

void bd_picker_toastShow(NSString *message) {
    UIView *view = [UIApplication sharedApplication].keyWindow;
    UILabel *toastView = bd_picker_toastView(message);
    CGSize parent = view.frame.size;
    CGSize toast = toastView.frame.size;
    toastView.frame = CGRectMake((parent.width - toast.width)/2,
                                 (parent.height - toast.height)/2,
                                 toast.width,
                                 toast.height);
    [view addSubview:toastView];
    [UIView animateWithDuration:0.2f delay:2.0f options:(UIViewAnimationOptionCurveLinear) animations:^{
        toastView.alpha = 0;
    } completion:^(BOOL finished) {
        [toastView removeFromSuperview];
    }];
}

static const void *BDCSToastActiveKey = &BDCSToastActiveKey;

static UIActivityIndicatorView *bd_picker_loadingView() {
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicatorView.hidesWhenStopped = YES;
    indicatorView.center = CGPointMake(50, 50);

    return indicatorView;
}

static UIView *bd_picker_activityView() {
    UIView *activityView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100)];
    activityView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    activityView.layer.cornerRadius = 10;
    activityView.alpha = 0.8;

    return activityView;
}

void bd_picker_loadingShow() {
    UIView * view = [UIApplication sharedApplication].keyWindow;
    UIView *activityView = bd_picker_activityView();
    UIActivityIndicatorView *indicatorView = bd_picker_loadingView();
    [activityView addSubview:indicatorView];

    activityView.center = view.center;

    objc_setAssociatedObject(view, BDCSToastActiveKey, activityView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [view addSubview:activityView];
    [indicatorView startAnimating];
}

void bd_picker_loadingCancel() {
    UIView * view = [UIApplication sharedApplication].keyWindow;
    UIView *activityView = objc_getAssociatedObject(view, BDCSToastActiveKey);
    if (![activityView isKindOfClass:[UIView class]]) {
        return;
    }
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         activityView.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [activityView.subviews enumerateObjectsUsingBlock:^(UIActivityIndicatorView *indicatorView, NSUInteger idx, BOOL *stop) {
                             if ([indicatorView isKindOfClass:[UIActivityIndicatorView class]]) {
                                 [indicatorView stopAnimating];
                             }
                         }];
                         [activityView removeFromSuperview];
                     }];
    objc_setAssociatedObject(view, BDCSToastActiveKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>


void bd_picker_toastShow(NSString *message) {
    
}

void bd_picker_loadingShow(void) {
    
}

void bd_picker_loadingCancel(void) {
    
}



#endif



