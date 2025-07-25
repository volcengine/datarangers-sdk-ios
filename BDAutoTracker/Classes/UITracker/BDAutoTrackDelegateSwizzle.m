//
//  BDAutoTrackDelegateSwizzle.m
//  Pods-ProjectTest0
//
//  Created by bytedance on 2023/9/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackDelegateSwizzle.h"
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackUtility.h"

#pragma BDAutoTrackDelegateSwizzleData
@interface BDAutoTrackDelegateSwizzleData : NSObject

@property (nonatomic, copy) bdautotrack_delegate_swizzle_block swizzleBlock;
@property (nonatomic, copy) bdautotrack_delegate_decorator_block decoratorBlock;
@property (nonatomic, copy) bdautotrack_delegate_noselector_block noselectorBlock;

@end

@implementation BDAutoTrackDelegateSwizzleData

@end



#pragma BDAutoTrackDelegateForwardData
@implementation BDAutoTrackDelegateForwardData

- (instancetype)initWithDelegate:(id)delegate forwardTarget:(id)forwardTarget;
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.forwardTarget = forwardTarget;
    }
    return self;
}

- (id)target
{
    if (self.forwardTarget) {
        return self.forwardTarget;
    }
    if (self.delegate) {
        return self.delegate;
    }
    return nil;
}

@end



#pragma BDAutoTrackDelegateIMPData
@interface BDAutoTrackDelegateIMPData : NSObject

@property (nonatomic, assign) IMP imp;
@property (nonatomic, assign) SEL selector;

@end

@implementation BDAutoTrackDelegateIMPData

@end



#pragma BDAutoTrackDelegateIMP
@interface BDAutoTrackDelegateIMP ()

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSMutableDictionary *impDict;

@end

@implementation BDAutoTrackDelegateIMP

- (instancetype)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.impDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)save:(IMP)imp selector:(SEL)selector
{
    NSString *key = NSStringFromSelector(selector);
    BDAutoTrackDelegateIMPData *data = [self.impDict objectForKey:key];
    if (!data) {
        data = [BDAutoTrackDelegateIMPData new];
    }
    data.imp = imp;
    data.selector = selector;
    [self.impDict setObject:data forKey:key];
}

- (IMP)load:(SEL)selector
{
    NSString *key = NSStringFromSelector(selector);
    BDAutoTrackDelegateIMPData *data = [self.impDict objectForKey:key];
    if (data) {
        return data.imp;
    }
    return NULL;
}

@end



#pragma BDUBADelegateSwizzle
@interface BDAutoTrackDelegateSwizzle () {
    Class                        targetClass;
    NSMutableDictionary         *swizzleDict;
    NSMutableArray         *swizzleSelectors;
    Class                        markerClass;
    SEL                       markerSelector;
    NSMapTable             *delegateIMPTable;
}

@end

@implementation BDAutoTrackDelegateSwizzle

- (instancetype)initWithTarget:(Class)targetClass
{
    self = [super init];
    if (self) {
        self->targetClass = targetClass;
        self->swizzleDict = [NSMutableDictionary dictionary];
        self->swizzleSelectors = [NSMutableArray array];
        self->delegateIMPTable = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void)markWith:(SEL)markerSelector markerClass:(Class)markerClass
{
    self->markerSelector = markerSelector;
    self->markerClass = markerClass;
}

- (void)delegateSelector:(SEL)selector
            swizzleBlock:(bdautotrack_delegate_swizzle_block)swizzleBlock
          decoratorBlock:(bdautotrack_delegate_decorator_block)decoratorBlock
         noselectorBlock:(bdautotrack_delegate_noselector_block)noselectorBlock
{
    NSString *selectorStr = NSStringFromSelector(selector);
    BDAutoTrackDelegateSwizzleData *swizzleData = [BDAutoTrackDelegateSwizzleData new];
    swizzleData.swizzleBlock = swizzleBlock;
    swizzleData.decoratorBlock = decoratorBlock;
    swizzleData.noselectorBlock = noselectorBlock;
    [self->swizzleDict setObject:swizzleData forKey:selectorStr];
    [self->swizzleSelectors addObject:selectorStr];
}

- (void)swizzleDelegate
{
    static IMP originIMP;
    id block = ^(id instance, id delegate){
        if (originIMP) {
            bd_run_in_main_thread_sync(^{
                [self beforeSetDelegate:delegate instance:instance];
            });
            
            ((void ( *)(id, SEL, id))originIMP)(instance, @selector(setDelegate:), delegate);
        }
    };
    originIMP = bd_swizzle_instance_methodWithBlock(self->targetClass, @selector(setDelegate:), block);
}

- (void)save:(IMP)imp selector:(SEL)selector forDelegate:(id)delegate
{
    BDAutoTrackDelegateIMP *delegateIMP = [self->delegateIMPTable objectForKey:delegate];
    if (!delegateIMP) {
        delegateIMP = [[BDAutoTrackDelegateIMP alloc] initWithDelegate:delegate];
    }
    [delegateIMP save:imp selector:selector];
    [self->delegateIMPTable setObject:delegateIMP forKey:delegate];
}

- (IMP)load:(SEL)selector forDelegate:(id)delegate
{
    BDAutoTrackDelegateIMP *delegateIMP = [self->delegateIMPTable objectForKey:delegate];
    if (delegateIMP) {
        return [delegateIMP load:selector];
    }
    return NULL;
}

#pragma BDUBADelegateSwizzle delegate

- (void)swizzleDelegateForwardingTargetForSelector:(id)delegate selectorSet:(NSMutableSet *)selectorSet
{
    SEL selector = @selector(forwardingTargetForSelector:);
    id block = ^id(id instance, SEL aSelector){
        IMP originIMP = [self load:selector forDelegate:delegate];
        if (originIMP) {
            __block id returnValue;
            returnValue = ((id ( *)(id, SEL, SEL))originIMP)(instance, selector, aSelector);
            
            bd_run_in_main_thread_sync(^{
                returnValue = [self afterForwardingTargetForSelector:aSelector instance:instance returnValue:returnValue];
            });
            
            return returnValue;
        }
        return nil;
    };
    IMP originIMP = bd_swizzle_instance_methodWithBlock([delegate class], selector, block);
    [self save:originIMP selector:selector forDelegate:delegate];
}

- (void)inject:(id)delegate once:(dispatch_block_t)block
{
    if ([delegate respondsToSelector:self->markerSelector]) {
        return;
    }
    
    block();
    bd_swizzle_instance_addMethod(object_getClass(delegate), self->markerSelector, self->markerClass);
}

- (void)beforeSetDelegate:(id)delegate instance:(id)instance
{
    if (!delegate) {
        return;
    }
    
    [self inject:delegate once:^{
        NSMutableSet *selectorSet = [NSMutableSet set];
        for (NSString *selectorStr in self->swizzleSelectors) {
            SEL selector = NSSelectorFromString(selectorStr);
            if (![delegate respondsToSelector:selector]) {
                [self executeNoSelectorBlock:delegate withSelector:selectorStr];
            }
            
            if (bd_swizzle_has_selector(delegate, selector)) {
                [self executeSwizzleBlock:delegate withSelector:selectorStr];
                continue;
            }
            
            [selectorSet addObject:selectorStr];
        }
        
        if (selectorSet.count > 0) {
            [self swizzleDelegateForwardingTargetForSelector:delegate selectorSet:selectorSet];
        }
    }];
}

- (id)afterForwardingTargetForSelector:(SEL)aSelector instance:(id)instance returnValue:(id)returnValue
{
    id decorator = [self executeDecoratorBlock:instance withSelector:NSStringFromSelector(aSelector) forwardTarget:returnValue];
    if (decorator) {
        return decorator;
    }
    return returnValue;
}

- (void)executeSwizzleBlock:(id)delegate withSelector:(NSString *)selectorStr
{
    BDAutoTrackDelegateSwizzleData *swizzleData = [self->swizzleDict objectForKey:selectorStr];
    if (swizzleData && swizzleData.swizzleBlock) {
        swizzleData.swizzleBlock(delegate);
    }
}

- (id)executeDecoratorBlock:(id)delegate withSelector:(NSString *)selectorStr forwardTarget:(id)target
{
    BDAutoTrackDelegateSwizzleData *swizzleData = [self->swizzleDict objectForKey:selectorStr];
    if (swizzleData && swizzleData.decoratorBlock) {
        BDAutoTrackDelegateForwardData *delegateForwardData = [[BDAutoTrackDelegateForwardData alloc] initWithDelegate:delegate forwardTarget:target];
        return swizzleData.decoratorBlock(delegateForwardData);
    }
    return nil;
}

- (void)executeNoSelectorBlock:(id)delegate withSelector:(NSString *)selectorStr
{
    BDAutoTrackDelegateSwizzleData *swizzleData = [self->swizzleDict objectForKey:selectorStr];
    if (swizzleData && swizzleData.noselectorBlock) {
        swizzleData.noselectorBlock(delegate);
    }
}

@end
