//
//  UICollectionView+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UICollectionView+AutoTrack.h"
#import <objc/runtime.h>
#import "UIResponder+AutoTrack.h"
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"
#import "BDDelegateDecorator.h"

@interface BDCollectionViewDelegateDecorator : BDAutoTrackDecorator<UICollectionViewDelegate>

@end

@implementation BDCollectionViewDelegateDecorator

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    bd_ui_trackCollectionView(collectionView, indexPath);
    NSArray *targets= self.targets.allObjects;
    if (targets.count > 0) {
        SEL originalForwardInvocationSEL = @selector(forwardInvocation:);
        SEL aSelector = @selector(collectionView:didSelectItemAtIndexPath:);
        for (NSObject *target in targets) {
            if (bd_swizzle_has_selector(target, aSelector)) {
                id<UICollectionViewDelegate> delegate = (id<UICollectionViewDelegate>)target;
                [delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
            } else {
                NSMethodSignature *methodSignature = [target methodSignatureForSelector:aSelector];
                if (methodSignature.numberOfArguments != 4) {
                    return;
                }
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                [invocation setSelector:aSelector];
                [invocation setArgument:&collectionView atIndex:2];
                [invocation setArgument:&indexPath atIndex:3];
                ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(target, originalForwardInvocationSEL, invocation);
            }
        }
    }
}

- (BOOL)bd_isCollectionViewTrackerDecorator {
    return YES;
}

@end


@implementation UICollectionView (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BDAutoTrackSwizzle *swizzle = [BDAutoTrackSwizzle new];
        swizzle.originIMP = bd_swizzle_instance_methodWithBlock([self class], @selector(setDelegate:), ^(UICollectionView *_self, id delegate){
            if (swizzle.originIMP) {
                if (delegate == nil) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), nil);
                    return;
                }
                
                if (bd_swizzle_has_selector(delegate, @selector(bd_isCollectionViewTrackerDecorator))) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
                    return;
                }
                
                Class delegateClass = object_getClass(delegate);
                SEL didSelectItemSelector = @selector(collectionView:didSelectItemAtIndexPath:);
                if (bd_swizzle_has_selector(delegate, didSelectItemSelector)) {
                    bd_swizzle_instance_addMethod(delegateClass,
                                                  @selector(bd_isCollectionViewTrackerDecorator),
                                                  BDCollectionViewDelegateDecorator.class);
                    BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                    id delegateBlock = ^void (id delegateSelf, UICollectionView *view, NSIndexPath *indexPath) {
                        bd_ui_trackCollectionView(view, indexPath);
                        if (delegateSwizzle.originIMP) {
                            return ((void ( *)(id, SEL, UICollectionView *, NSIndexPath *))delegateSwizzle.originIMP)(delegateSelf, didSelectItemSelector, view, indexPath);
                        }
                    };
                    delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock([delegate class], didSelectItemSelector, delegateBlock);
                    
                    BDDelegateDecorator *delegateDecorator = [BDDelegateDecorator decoratorForDelegate:delegate];
                    [delegateDecorator removeDecoratorForSelector:didSelectItemSelector];
                } else {
                    BOOL hasMark = bd_swizzle_has_selector(delegate, @selector(bd_decoratorMark));
                    if (!hasMark) {
                        id responder = [delegate forwardingTargetForSelector:didSelectItemSelector];
                        if (responder != nil && bd_swizzle_has_selector(responder, didSelectItemSelector)) {
                            if (!bd_swizzle_has_selector(responder, @selector(bd_isCollectionViewTrackerDecorator))) {
                                bd_swizzle_instance_addMethod(object_getClass(responder),
                                                              @selector(bd_isCollectionViewTrackerDecorator),
                                                              BDCollectionViewDelegateDecorator.class);
                                
                                BDAutoTrackSwizzle *responderSwizzle = [BDAutoTrackSwizzle new];
                                id delegateBlock = ^void (id delegateSelf, UICollectionView *view, NSIndexPath *indexPath) {
                                    bd_ui_trackCollectionView(view, indexPath);
                                    if (responderSwizzle.originIMP) {
                                        return ((void ( *)(id, SEL, UICollectionView *, NSIndexPath *))responderSwizzle.originIMP)(delegateSelf, didSelectItemSelector, view, indexPath);
                                    }
                                };
                                responderSwizzle.originIMP = bd_swizzle_instance_methodWithBlock([responder class], didSelectItemSelector, delegateBlock);
                            }
                            ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
                            return;
                        }
                    }
                    
                    if (!hasMark) {
                        bd_swizzle_instance_addMethod(delegateClass,
                                                      @selector(bd_decoratorMark),
                                                      BDDelegateDecorator.class);
                        BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                        id delegateBlock = ^id (id delegateSelf, SEL aSelector) {
                            id tagret = nil;
                            if (delegateSwizzle.originIMP) {
                                tagret = ((id ( *)(id, SEL, SEL))delegateSwizzle.originIMP)(delegateSelf, @selector(forwardingTargetForSelector:), aSelector);
                            }
                            
                            BDDelegateDecorator *decorator = [BDDelegateDecorator decoratorForDelegate:delegateSelf];
                            BDAutoTrackDecorator *responder = [decorator decoratorForSelector:aSelector];
                            if (responder) {
                                if (tagret
                                    && tagret != delegateSelf
                                    && tagret != responder) {
                                    [responder addTarget:tagret];
                                }
                                
                                return responder;
                            }
                            
                            return tagret;
                        };
                        delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass, @selector(forwardingTargetForSelector:), delegateBlock);
                    }
                    BDDelegateDecorator *delegateDecorator = [BDDelegateDecorator decoratorForDelegate:delegate];
                    BDCollectionViewDelegateDecorator *decorator = [[BDCollectionViewDelegateDecorator alloc] initWithTarget:delegate];
                    [delegateDecorator setDecorator:decorator forSelector:didSelectItemSelector];
                }
                
                
                ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
                
            }
        });
    });
}

@end
