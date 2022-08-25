//
//  VEInstallActivateStorageContent.h
//  VEInstall
//
//  Created by KiBen on 2021/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kVEInstallActivateChannelKey = @"ve_install_activate_channel";
static NSString *const kVEInstallActivateReleaseVersionKey = @"ve_install_activate_release_version";
static NSString *const kVEInstallActivateBuildVersionKey = @"ve_install_activate_build_version";
static NSString *const kVEInstallActivateStateKey = @"ve_install_activate_state";

@interface VEInstallActivateStorageContent : NSObject

@property (nonatomic, copy, readonly) NSString *channel;
@property (nonatomic, copy, readonly) NSString *releaseVersion;
@property (nonatomic, copy, readonly) NSString *buildVersion;
@property (nonatomic, assign, readonly) BOOL isActivated;

- (instancetype)initWithContentDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
