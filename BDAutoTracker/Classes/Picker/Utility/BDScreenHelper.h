//
//  BDScreenHelper.h
//  Applog
//
//  Created by bob on 2019/2/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN CGFloat bd_picker_safeAreaInsetsTop(void);
FOUNDATION_EXTERN CGFloat bd_picker_safeAreaInsetsBottom(void);
FOUNDATION_EXTERN CGSize bd_picker_screenSize(void);

FOUNDATION_EXTERN UIImage * bd_picker_imageForView(UIView *view);
FOUNDATION_EXTERN UIImage * bd_picker_combineImage(UIImage *first, UIImage *second);

NS_ASSUME_NONNULL_END
