//
//  UIAlertController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIAlertController+AutoTrack.h"
#import "UIViewController+TrackInfo.h"
#import "BDTrackConstants.h"
#import "BDAutoTrackSwizzle.h"


@implementation UIAlertController (AutoTrack)

- (NSDictionary *)bd_pageTrackInfo {
    NSMutableDictionary *alertVCInfo = [NSMutableDictionary dictionary];

    NSString *pageID = [self bdAutoTrackPageID];
    if (pageID.length > 0) {
        [alertVCInfo setValue:pageID forKey:kBDAutoTrackEventViewID];
    }

    /// alert only
    [alertVCInfo setValue:NSStringFromClass([self class]) forKey:kBDAutoTrackEventAlertVC];
    [alertVCInfo setValue:self.title forKey:kBDAutoTrackEventAlertTitle];

    [alertVCInfo setValue:self.message forKey:kBDAutoTrackEventAlertMessage];
    NSString *style = self.preferredStyle == UIAlertControllerStyleAlert ? @"alert" : @"actionSheet";
    [alertVCInfo setValue:style forKey:kBDAutoTrackEventAlertStyle];
    NSDictionary *extra = [self bdAutoTrackExtraInfos];
    if ([extra isKindOfClass:[NSDictionary class]] && extra.count > 0) {
        [alertVCInfo setValue:extra forKey:kBDAutoTrackEventDataCustom];
    }
    
    // 自定义属性
    NSDictionary *properties = [self bdAutoTrackPageProperties];
    if ([properties isKindOfClass:[NSDictionary class]] && properties.count > 0) {
        [alertVCInfo addEntriesFromDictionary:properties];
    }

    return alertVCInfo;
}

@end
