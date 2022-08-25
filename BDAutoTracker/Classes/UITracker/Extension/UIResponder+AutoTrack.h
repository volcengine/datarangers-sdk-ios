//
//  UIResponder+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

// view path

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kBDViewPathSeperator;

@interface UIResponder (AutoTrack)

- (NSString *)bd_responderPath;

@end

NS_ASSUME_NONNULL_END
