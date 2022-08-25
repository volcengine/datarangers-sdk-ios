//
//  BDPickerView.h

//
//  Created by bob on 2019/4/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class AppLogPickerView;

@interface AppLogPickerView : NSObject

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, weak, readonly, nullable) UIView *view;

@property (nonatomic, copy, readonly) NSString *elementPath;
@property (nonatomic, assign, readonly) CGRect frameInWindow;
@property (nonatomic, assign, readonly) CGRect wrapperFrameInWindow;
@property (nonatomic, weak, readonly, nullable) AppLogPickerView *superView;
@property (nonatomic, strong,readonly, nullable) NSArray<AppLogPickerView *> *subViews;
@property (nonatomic, assign, readonly) BOOL isWebView;
@property (nonatomic, assign, readonly) NSInteger zIndex;

#pragma mark - heat
@property (nonatomic, copy, readonly)   NSString    *pageKey;
@property (nonatomic, copy, readonly)   NSArray     *positions;


+ (instancetype)pickerViewAt:(CGPoint)point;

- (instancetype)initWithView:(UIView *)view;
- (instancetype)initWithWebView:(UIView *)webview data:(NSDictionary *)data;

- (UIViewController *)controller;
- (NSDictionary *)viewPickerInfo;
- (NSDictionary *)pagePickerInfo;

- (NSArray<AppLogPickerView *> *)pickerViewAt:(CGPoint)point;

#pragma mark - Simulator

- (NSMutableDictionary *)simulatorUploadInfoWithWebContainer:(NSMutableArray *)container;
- (NSMutableArray *)webViewSimulatorUploadInfo;
- (NSMutableDictionary *)simulatorUploadInfoPageInfoWithDom:(NSArray *)dom;

@end

NS_ASSUME_NONNULL_END
