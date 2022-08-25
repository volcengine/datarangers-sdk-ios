//
//  VEInstallActivateStorageContent.m
//  VEInstall
//
//  Created by KiBen on 2021/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallActivateStorageContent.h"

@implementation VEInstallActivateStorageContent

- (instancetype)initWithContentDict:(NSDictionary *)dict {
    if (self = [super init]) {
        _channel = dict[kVEInstallActivateChannelKey];
        _releaseVersion = dict[kVEInstallActivateReleaseVersionKey];
        _buildVersion = dict[kVEInstallActivateBuildVersionKey];
        _isActivated = [dict[kVEInstallActivateStateKey] boolValue];
    }
    return self;
}
@end
