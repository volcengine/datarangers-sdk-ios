//
//  WKWebView+Picker.h
//  Applog
//
//  Created by bob on 2019/4/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AppLogPickerView;

@interface WKWebView (Picker)

@property (nonatomic, assign) BOOL bd_pickJSInjected;

- (nullable AppLogPickerView *)bd_pickerView;

@end

NS_ASSUME_NONNULL_END
