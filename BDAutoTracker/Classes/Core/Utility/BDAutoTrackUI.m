//
//  BDAutoTrackUI.m
//  RangersAppLog
//
//  Created by bytedance on 8/2/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackUI.h"

#if TARGET_OS_IOS
#import "UIView+Toast.h"
#endif

@implementation BDAutoTrackUI

+ (void)toast:(NSString *)message
{
    if (![message isKindOfClass:NSString.class] || message.length == 0) {
        return;
    }
#if TARGET_OS_IOS
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
        [window bd_makeToast:message];
    });
#endif
}

@end
