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

#elif __has_include(<AppKit/AppKit.h>)

#endif






#endif
