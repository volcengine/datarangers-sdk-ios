//
//  UIAlertAction+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/17.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIAlertAction+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"


@implementation UIAlertAction (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Method_Imp = nil;
    dispatch_once(&onceToken, ^{
        original_Method_Imp = bd_swizzle_class_methodWithBlock([self class], @selector(actionWithTitle:style:handler:),^UIAlertAction *(Class _self, NSString *title, UIAlertActionStyle style, void (^handler)(UIAlertAction *action)){
            if (original_Method_Imp) {
                return ((UIAlertAction * ( *)(Class, SEL, NSString *, UIAlertActionStyle, id handler))original_Method_Imp)(_self, @selector(actionWithTitle:style:handler:), title, style,^(UIAlertAction * _Nonnull action) {
                    bd_ui_trackAlertAction(title);
                    if (handler) {
                        handler(action);
                    }
                });
            }

            return [_self new];
        });
    });
}

@end
