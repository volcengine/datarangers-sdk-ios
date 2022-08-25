//
//  BDDelegateDecorator.h
//  RangersAppLog
//
//  Created by bob on 2020/2/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackDecorator;

@interface BDDelegateDecorator : NSObject

@property (nonatomic, strong) BDDelegateDecorator *bd_delegateDecorator;

+ (instancetype)decoratorForDelegate:(id)delegate;

- (void)setDecorator:(BDAutoTrackDecorator *)decorator forSelector:(SEL)aSelector;
- (nullable BDAutoTrackDecorator *)decoratorForSelector:(SEL)aSelector;
- (void)bd_decoratorMark;

@end

@interface BDAutoTrackDecorator : NSObject

@property (nonatomic, strong, readonly) NSHashTable *targets;
- (nullable instancetype)initWithTarget:(id)target;
- (void)addTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
