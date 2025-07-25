//
//  UIApplication+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIApplication+AutoTrack.h"
#import "NSObject+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"

@implementation UIApplication (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static IMP original_Method_Imp = nil;
    dispatch_once(&onceToken, ^{
        original_Method_Imp = bd_swizzle_instance_methodWithBlock([self class],@selector(sendAction:to:from:forEvent:),^ BOOL (UIApplication *_self, SEL action, id to, id from, UIEvent *event){
            if (original_Method_Imp) {

                if (action && to && [to isKindOfClass:[NSObject class]]) {
                    if ([from isKindOfClass:[UIBarButtonItem class]] && ![to bd_AutoTrackInternalItem]) {
                        UIBarButtonItem *item = (UIBarButtonItem *)from;
                        bd_ui_trackNavigationButton(item, event);

                    }  else if (([event isKindOfClass:[UIEvent class]] && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded)
                                || [from isKindOfClass:[UISwitch class]]
                                || [from isKindOfClass:[UIStepper class]]
                                || [from isKindOfClass:[UISegmentedControl class]]
                                || [from isKindOfClass:[UIDatePicker class]]) {
                        if ([from isKindOfClass:[UIControl class]]
                            && ![from isKindOfClass:[UISlider class]]) {
                            NSString *clazzName = NSStringFromClass([from class]);
                            if (![clazzName hasPrefix:@"_"]) {
                                //if ([to isKindOfClass:[UITabBar class]]) {}
                                UIControl *control = (UIControl *)from;
                                bd_ui_trackControl(control, event);
                            }
                        }
                    }
                }

                return  ((BOOL ( *)(id, SEL, SEL, id, id, UIEvent *))original_Method_Imp)(_self, @selector(sendAction:to:from:forEvent:), action, to, from, event);
            }
            return NO;
        });
    });
}

@end
