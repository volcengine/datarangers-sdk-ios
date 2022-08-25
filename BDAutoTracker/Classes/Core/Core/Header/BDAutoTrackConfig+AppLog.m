//
//  BDAutoTrackConfig+AppLog.m
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackConfig+AppLog.h"
#import <objc/runtime.h>

@implementation BDAutoTrackConfig (AppLog)

/* TrackEvent */
- (BOOL)trackEventEnabled {
    return [objc_getAssociatedObject(self, @selector(trackEventEnabled)) boolValue];
}

- (void)setTrackEventEnabled:(BOOL)enabled {
    objc_setAssociatedObject(self, @selector(trackEventEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* AutoTrack */
- (BOOL)autoTrackEnabled {
    return [objc_getAssociatedObject(self, @selector(autoTrackEnabled)) boolValue];
}

- (void)setAutoTrackEnabled:(BOOL)autoTrackEnabled {
    objc_setAssociatedObject(self, @selector(autoTrackEnabled), @(autoTrackEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* H5AutoTrack */
- (BOOL)H5AutoTrackEnabled {
    return [objc_getAssociatedObject(self, @selector(H5AutoTrackEnabled)) boolValue];
}

- (void)setH5AutoTrackEnabled:(BOOL)H5AutoTrackEnabled {
    objc_setAssociatedObject(self, @selector(H5AutoTrackEnabled), @(H5AutoTrackEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* screenOrientationEnabled */
- (BOOL)screenOrientationEnabled {
    return [objc_getAssociatedObject(self, @selector(screenOrientationEnabled)) boolValue];
}

- (void)setScreenOrientationEnabled:(BOOL)screenOrientationEnabled {
    objc_setAssociatedObject(self, @selector(screenOrientationEnabled), @(screenOrientationEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* trackGPSLocationEnabled */
- (BOOL)trackGPSLocationEnabled {
    return [objc_getAssociatedObject(self, @selector(trackGPSLocationEnabled)) boolValue];
}

- (void)setTrackGPSLocationEnabled:(BOOL)trackGPSLocationEnabled {
    objc_setAssociatedObject(self, @selector(trackGPSLocationEnabled), @(trackGPSLocationEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* trackPageLeaveEnabled */
- (BOOL)trackPageLeaveEnabled {
    return [objc_getAssociatedObject(self, @selector(trackPageLeaveEnabled)) boolValue];
}

- (void)setTrackPageLeaveEnabled:(BOOL)trackPageLeaveEnabled {
    objc_setAssociatedObject(self, @selector(trackPageLeaveEnabled), @(trackPageLeaveEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)gameModeEnable {
    return [objc_getAssociatedObject(self, @selector(gameModeEnable)) boolValue];
}

- (void)setGameModeEnable:(BOOL)gameModeEnable {
    objc_setAssociatedObject(self, @selector(gameModeEnable), @(gameModeEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)autoActiveUser {
    return [objc_getAssociatedObject(self, @selector(autoActiveUser)) boolValue];
}

- (void)setAutoActiveUser:(BOOL)autoActiveUser {
    objc_setAssociatedObject(self, @selector(autoActiveUser), @(autoActiveUser), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)showDebugLog {
    return [objc_getAssociatedObject(self, @selector(showDebugLog)) boolValue];
}

- (void)setShowDebugLog:(BOOL)showDebugLog {
    objc_setAssociatedObject(self, @selector(showDebugLog), @(showDebugLog), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDAutoTrackLogger)logger {
    return objc_getAssociatedObject(self, @selector(logger));
}

- (void)setLogger:(BDAutoTrackLogger)logger {
    BDAutoTrackLogger value = [logger copy];
    objc_setAssociatedObject(self, @selector(logger), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)logNeedEncrypt {
    return [objc_getAssociatedObject(self, @selector(logNeedEncrypt)) boolValue];
}

- (void)setLogNeedEncrypt:(BOOL)logNeedEncrypt {
    objc_setAssociatedObject(self, @selector(logNeedEncrypt), @(logNeedEncrypt), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)autoFetchSettings {
    return [objc_getAssociatedObject(self, @selector(autoFetchSettings)) boolValue];
}

- (void)setAutoFetchSettings:(BOOL)autoFetchSettings {
    objc_setAssociatedObject(self, @selector(autoFetchSettings), @(autoFetchSettings), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)abEnable {
    return [objc_getAssociatedObject(self, @selector(abEnable)) boolValue];
}

- (void)setAbEnable:(BOOL)abEnable {
    objc_setAssociatedObject(self, @selector(abEnable), @(abEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
