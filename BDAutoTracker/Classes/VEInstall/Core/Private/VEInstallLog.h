//
//  VEInstallLog.h
//  Pods
//
//  Created by KiBen on 2021/9/3.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef VEInstallLog_h
#define VEInstallLog_h

#import <Foundation/Foundation.h>

#if DEBUG
#define InstallLog(fmt, ...)    NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define InstallLog(...)            (void)0
#endif

#endif /* VEInstallLog_h */
