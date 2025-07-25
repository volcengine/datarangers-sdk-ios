//
//  BDAutoTrackMainBundle.m
//  Pods
//
//  Created by bytedance on 2023/1/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackMainBundle.h"

NSBundle *bd_app_main_bundle(void) {
    NSBundle *bundle = [NSBundle mainBundle];
    if (bd_is_extension()) {
        NSURL *url = [[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
        bundle = [NSBundle bundleWithURL:url];
    }
    return bundle;
}

BOOL bd_is_extension(void) {
    NSBundle *bundle = [NSBundle mainBundle];
    return [[bundle.bundleURL pathExtension] isEqualToString:@"appex"];
}
