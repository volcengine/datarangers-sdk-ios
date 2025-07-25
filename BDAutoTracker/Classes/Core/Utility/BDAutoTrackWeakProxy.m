//
//  BDAutoTrackWeakProxy.m
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackWeakProxy.h"

@interface BDAutoTrackWeakProxy ()

@property (nonatomic, weak) id target;

@end

@implementation BDAutoTrackWeakProxy

- (instancetype)initWithTarget:(id)target {
    if (!target) {
        return nil;
    }

    self.target = target;

    return self;
}

#pragma mark - standard

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (!self.target) {
        void *nullPointer = NULL;
        [invocation setReturnValue:&nullPointer];
        return;
    }
    [invocation invokeWithTarget:self.target];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (!self.target) {
       return [NSObject instanceMethodSignatureForSelector:@selector(init)];
    }
    return [self.target methodSignatureForSelector:sel];
}

#pragma mark - extra work

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.target;
}


@end
