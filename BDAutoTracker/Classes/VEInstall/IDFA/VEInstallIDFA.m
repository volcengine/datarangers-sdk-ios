//
//  VEInstallIDFA.h
//  VEInstall
//
//  Created by KiBen on 2021/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallIDFA.h"
#import <AdSupport/ASIdentifierManager.h>

@implementation VEInstallIDFA

@dynamic idfa;

+ (NSString *)idfa {
    
    static dispatch_once_t onceToken;
    static NSString *_idfa = nil;
    dispatch_once(&onceToken, ^{
        _idfa = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
    });
    return _idfa;
}

@end
