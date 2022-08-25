//
//  BDDelegateDecorator.m
//  RangersAppLog
//
//  Created by bob on 2020/2/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDDelegateDecorator.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "BDAutoTrackSwizzle.h"

@interface BDDelegateDecorator ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDAutoTrackDecorator *> *decorators;

@end

@implementation BDDelegateDecorator

- (instancetype)init {
    self = [super init];
    if (self) {
        self.decorators = [NSMutableDictionary new];
    }
    
    return self;
}

+ (instancetype)decoratorForDelegate:(id)delegate {
    BDDelegateDecorator *delegateDecorator = objc_getAssociatedObject(delegate, @selector(bd_delegateDecorator));
    if (!delegateDecorator) {
        delegateDecorator = [self new];
        objc_setAssociatedObject(delegate, @selector(bd_delegateDecorator), delegateDecorator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return delegateDecorator;
}


- (void)setDecorator:(BDAutoTrackDecorator *)decorator forSelector:(SEL)aSelector {
    if (decorator == nil || aSelector == nil) {
        return;
    }
    NSString *key = NSStringFromSelector(aSelector);
    [self.decorators setValue:decorator forKey:key];
}

- (BDAutoTrackDecorator *)decoratorForSelector:(SEL)aSelector {
    if (aSelector == nil) {
        return nil;
    }
    NSString *key = NSStringFromSelector(aSelector);
    
    return [self.decorators objectForKey:key];
}

- (void)bd_decoratorMark {
    
}

@end

@interface BDAutoTrackDecorator ()

@property (nonatomic, strong) NSHashTable *targets;

@end


@implementation BDAutoTrackDecorator

- (instancetype)initWithTarget:(id)target {
    if (target == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.targets = [NSHashTable weakObjectsHashTable];
        [self.targets addObject:target];
    }
    
    return self;
}

- (void)addTarget:(id)target {
    if (![self.targets containsObject:target]
        && target != self) {
        [self.targets addObject:target];
    }
}

@end
