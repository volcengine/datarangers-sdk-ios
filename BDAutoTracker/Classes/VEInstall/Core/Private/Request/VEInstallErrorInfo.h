//
//  VEInstallErrorInfo.h
//  Pods
//
//  Created by KiBen on 2021/9/26.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef VEInstallErrorInfo_h
#define VEInstallErrorInfo_h

#import <Foundation/Foundation.h>

static NSDictionary *VEInstall_error_info(NSInteger code, NSString *reason, id content) {
    
    NSString *contentInfo = [content description];
    if (content && [content isKindOfClass:[NSData class]]) {
        contentInfo = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
    }
    
    return @{
        @"code" : @(code),
        @"reason" : reason ?: @"",
        @"content" : contentInfo ?: @""
    };
    
}

#endif /* VEInstallErrorInfo_h */
