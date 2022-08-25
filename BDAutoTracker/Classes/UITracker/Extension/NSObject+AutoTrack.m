//
//  NSObject+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSObject+AutoTrack.h"
#import <objc/runtime.h>

@implementation NSObject (AutoTrack)

- (BOOL)bd_AutoTrackInternalItem {
    return [objc_getAssociatedObject(self, @selector(bd_AutoTrackInternalItem)) boolValue];
}

- (void)setBd_AutoTrackInternalItem:(BOOL)internal {
    objc_setAssociatedObject(self, @selector(bd_AutoTrackInternalItem), [NSNumber numberWithBool:internal], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSProxy (AutoTrack)

- (BOOL)bd_AutoTrackInternalItem {
    return [objc_getAssociatedObject(self, @selector(bd_AutoTrackInternalItem)) boolValue];
}

- (void)setBd_AutoTrackInternalItem:(BOOL)internal {
    objc_setAssociatedObject(self, @selector(bd_AutoTrackInternalItem), [NSNumber numberWithBool:internal], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
