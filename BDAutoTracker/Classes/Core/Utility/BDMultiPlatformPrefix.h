//
//  BDMultiPlatformPrefix.h
//  RangersAppLog
//
//  Created by 冯诚祺 on 1/6/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef BDMultiPlatformPrefix_h
#define BDMultiPlatformPrefix_h

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIKit.h>)

//#import <OneKit/NSData+OKGZIP.h>
//#import <OneKit/NSData+OKSecurity.h>
//#import <OneKit/NSData+OKDecorator.h>
//#import <OneKit/OKApplicationInfo.h>
//#import <OneKit/OKReachability.h>
//#import <OneKit/OKReachability+Cellular.h>
//#import <OneKit/OKConnection.h>

#elif __has_include(<AppKit/AppKit.h>)

//#import "NSDictionary+OK.h"
//#import "NSData+OKGZIP.h"
//#import "NSData+OKSecurity.h"
//#import "NSData+OKDecorator.h"
//#import "OKReachability.h"

#endif






#endif /* BDMultiPlatformAdapter_h */
