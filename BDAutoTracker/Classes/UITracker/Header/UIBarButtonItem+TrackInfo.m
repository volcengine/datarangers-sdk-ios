//
//  UIBarButtonItem+TrackInfo.m
//  Applog
//
//  Created by bob on 2019/1/21.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIBarButtonItem+TrackInfo.h"
#import <objc/runtime.h>
#import "BDTrackConstants.h"

@implementation UIBarButtonItem (TrackInfo)

- (NSString *)bdAutoTrackElementID {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackElementID));
}

- (void)setBdAutoTrackElementID:(NSString *)autoTrackID {
    objc_setAssociatedObject(self, @selector(bdAutoTrackElementID), autoTrackID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (NSString *)bdAutoTrackID {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackID));
}

- (void)setBdAutoTrackID:(NSString *)autoTrackID {
    objc_setAssociatedObject(self, @selector(bdAutoTrackID), autoTrackID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bdAutoTrackContent {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackContent));
}

- (void)setBdAutoTrackContent:(NSString *)content {
    objc_setAssociatedObject(self, @selector(bdAutoTrackContent), content, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
