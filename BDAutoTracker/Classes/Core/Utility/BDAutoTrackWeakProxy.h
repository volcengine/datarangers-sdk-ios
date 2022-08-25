//
//  BDAutoTrackWeakProxy.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (nullable instancetype)initWithTarget:(nullable id)target;

- (BOOL)respondsToSelector:(SEL)aSelector;

- (id)forwardingTargetForSelector:(SEL)aSelector;

@end

NS_ASSUME_NONNULL_END
