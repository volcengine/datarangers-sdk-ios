//
//  UIBarButtonItem+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIBarButtonItem+AutoTrack.h"
#import "UIBarButtonItem+TrackInfo.h"
#import "BDTrackConstants.h"

extern NSString *kBDViewPathSeperator;

@implementation UIBarButtonItem (AutoTrack)

- (void)bd_fillCustomInfo:(NSMutableDictionary *)result {
    NSString *title = [self bdAutoTrackContent];
    NSString *itemID = [self bdAutoTrackID];
    NSString *elementID = [self bdAutoTrackElementID];
    NSString *elementType = [self bd_elementType];
    if (itemID.length > 0) {
        [result setValue:itemID forKey:kBDAutoTrackEventViewID];
    }
    [result setValue:elementID ?: @"" forKey:kBDAutoTrackEventElementID];
    if (title.length > 0) {
        [result setValue:@[title] forKey:kBDAutoTrackEventViewTitle];
    }
    [result setValue:elementType forKey:kBDAutoTrackEventElementType];
    NSDictionary *extra = [self bdAutoTrackExtraInfos];
    if ([extra isKindOfClass:[NSDictionary class]] && extra.count > 0) {
        [result setValue:extra forKey:kBDAutoTrackEventDataCustom];
    }
    // 自定义属性
    NSDictionary *properties = [self bdAutoTrackViewProperties];
    if ([properties isKindOfClass:[NSDictionary class]] && properties.count > 0) {
        [result addEntriesFromDictionary:properties];
    }
}

- (NSString *)bd_elementType {
    return NSStringFromClass(self.class);
}


@end
