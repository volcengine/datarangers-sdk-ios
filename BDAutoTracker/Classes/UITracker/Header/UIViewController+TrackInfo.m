//
//  UIViewController+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UIViewController+TrackInfo.h"
#import <objc/runtime.h>

@implementation UIViewController (TrackInfo)

- (NSString *)bdAutoTrackPageTitle {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackPageTitle));
}

- (void)setBdAutoTrackPageTitle:(NSString *)pageTitle {
    objc_setAssociatedObject(self, @selector(bdAutoTrackPageTitle), pageTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (NSString *)bdAutoTrackPageID {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackPageID));
}

- (void)setBdAutoTrackPageID:(NSString *)pageID {
    objc_setAssociatedObject(self, @selector(bdAutoTrackPageID), pageID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (NSString *)bdAutoTrackPagePath {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackPagePath));
}

- (void)setBdAutoTrackPagePath:(NSString *)pagePath {
    objc_setAssociatedObject(self, @selector(bdAutoTrackPagePath), pagePath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary<NSString*, NSString *> *)bdAutoTrackExtraInfos {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackExtraInfos));
}

- (void)setBdAutoTrackExtraInfos:(NSDictionary<NSString*, NSString *> *)infos {
    objc_setAssociatedObject(self, @selector(bdAutoTrackExtraInfos), infos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary<NSString*, NSObject *> *)bdAutoTrackPageProperties {
    return objc_getAssociatedObject(self, @selector(bdAutoTrackPageProperties));
}

- (void)setBdAutoTrackPageProperties:(NSDictionary *)properties {
    objc_setAssociatedObject(self, @selector(bdAutoTrackPageProperties), properties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
