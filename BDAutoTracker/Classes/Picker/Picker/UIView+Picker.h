//
//  UIView+Picker.h
//  Applog
//
//  Created by bob on 2019/3/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AppLogPickerView;

@interface UIView (Picker)

- (BOOL)bd_hasAction;

- (UIView *)bd_pickedView;

- (NSDictionary *)bd_pickerInfo;

- (AppLogPickerView *)bd_pickerViewAt:(CGPoint)point;

- (nullable AppLogPickerView *)bd_pickerView;

@end

NS_ASSUME_NONNULL_END
