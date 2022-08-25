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

/// 下面两个方法是适配IGListKit
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.target;
}

/// IGListKit 实现如下 导致消息转发一些问题

/// handling unimplemented methods and nil target/interceptor
/// https://github.com/Flipboard/FLAnimatedImage/blob/76a31aefc645cc09463a62d42c02954a30434d7d/FLAnimatedImage/FLAnimatedImage.m#L786-L807
#if 0
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *nullPointer = NULL;
    [invocation setReturnValue:&nullPointer];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}
#endif


@end
