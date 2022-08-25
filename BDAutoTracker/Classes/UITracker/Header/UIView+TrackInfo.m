//
//  UIView+TrackInfo.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIView+TrackInfo.h"
#import <objc/runtime.h>

@implementation UIView (TrackInfo)

- (NSString *)bdAutoTrackElementID {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackElementID));
}

- (void)setBdAutoTrackElementID:(NSString *)autoTrackID {
    objc_setAssociatedObject(self, @selector(bdAutoTrackElementID), autoTrackID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bdAutoTrackViewID {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackViewID));
}

- (void)setBdAutoTrackViewID:(NSString *)autoTrackViewID {
    objc_setAssociatedObject(self, @selector(bdAutoTrackViewID), autoTrackViewID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bdAutoTrackViewContent {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackViewContent));
}

- (void)setBdAutoTrackViewContent:(NSString *)autoTrackViewContent {
    objc_setAssociatedObject(self, @selector(bdAutoTrackViewContent), autoTrackViewContent, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary<NSString*, NSString *> *)bdAutoTrackExtraInfos {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackExtraInfos));
}

- (void)setBdAutoTrackExtraInfos:(NSDictionary<NSString*, NSString *> *)infos {
    objc_setAssociatedObject(self, @selector(bdAutoTrackExtraInfos), infos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary<NSString*, NSObject *> *)bdAutoTrackViewProperties {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackViewProperties));
}

- (void)setBdAutoTrackViewProperties:(NSDictionary *)properties {
    objc_setAssociatedObject(self, @selector(bdAutoTrackViewProperties), properties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdAutoTrackIgnoreClick {
    NSNumber* item =  objc_getAssociatedObject(self, @selector(bdAutoTrackIgnoreClick));
    return [item boolValue];
}

- (void)setBdAutoTrackIgnoreClick:(BOOL)bdAutoTrackIgnoreClick {
    objc_setAssociatedObject(self, @selector(bdAutoTrackIgnoreClick), @(bdAutoTrackIgnoreClick), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end


