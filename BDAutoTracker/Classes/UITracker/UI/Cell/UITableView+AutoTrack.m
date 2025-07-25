//
//  UITableView+AutoTrack.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "UITableView+AutoTrack.h"
#import <objc/runtime.h>
#import "BDUIAutoTracker.h"
#import "BDAutoTrackSwizzle.h"
#import "BDDelegateDecorator.h"

@interface BDTableViewDelegateDecorator : BDAutoTrackDecorator<UITableViewDelegate>

@end

@implementation BDTableViewDelegateDecorator

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    bd_ui_trackTableView(tableView, indexPath);
    NSArray *targets= self.targets.allObjects;
    if (targets.count > 0) {
        SEL originalForwardInvocationSEL = @selector(forwardInvocation:);
        SEL aSelector = @selector(tableView:didSelectRowAtIndexPath:);
        for (NSObject *target in targets) {
            if (bd_swizzle_has_selector(target, aSelector)) {
                id<UITableViewDelegate> delegate = (id<UITableViewDelegate>)target;
                [delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
            } else {
                NSMethodSignature *methodSignature = [target methodSignatureForSelector:aSelector];
                if (methodSignature.numberOfArguments != 4) {
                    return;
                }
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                [invocation setSelector:aSelector];
                [invocation setArgument:&tableView atIndex:2];
                [invocation setArgument:&indexPath atIndex:3];
                ((void( *)(id, SEL, NSInvocation *))objc_msgSend)(target, originalForwardInvocationSEL, invocation);
            }
        }
    }
}

- (BOOL)bd_isTableViewTrackerDecorator {
    return YES;
}

@end

@implementation UITableView (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BDAutoTrackSwizzle *swizzle = [BDAutoTrackSwizzle new];
        swizzle.originIMP = bd_swizzle_instance_methodWithBlock([self class], @selector(setDelegate:), ^(UITableView *_self, id delegate){
            if (swizzle.originIMP) {
                if (delegate == nil) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), nil);
                    return;
                }
                if (bd_swizzle_has_selector(delegate, @selector(bd_isTableViewTrackerDecorator))) {
                    ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
                    return;
                }
                Class delegateClass = object_getClass(delegate);
                SEL didSelectItemSelector = @selector(tableView:didSelectRowAtIndexPath:);
                if (bd_swizzle_has_selector(delegate, didSelectItemSelector)) {
                    bd_swizzle_instance_addMethod(delegateClass,
                                                  @selector(bd_isTableViewTrackerDecorator),
                                                  BDTableViewDelegateDecorator.class);
                    
                    BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                    id delegateBlock = ^void (id delegateSelf, UITableView *tableView, NSIndexPath *indexPath) {
                        bd_ui_trackTableView(tableView, indexPath);
                        if (delegateSwizzle.originIMP) {
                            return ((void ( *)(id, SEL, UITableView *, NSIndexPath *))delegateSwizzle.originIMP)(delegateSelf, didSelectItemSelector, tableView, indexPath);
                        }
                    };
                    delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass, didSelectItemSelector, delegateBlock);
                    
                    BDDelegateDecorator *delegateDecorator = [BDDelegateDecorator decoratorForDelegate:delegate];
                    [delegateDecorator removeDecoratorForSelector:didSelectItemSelector];
                } else {
                    BOOL hasMark = bd_swizzle_has_selector(delegate, @selector(bd_decoratorMark));
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
                        delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass,
                                                                                        @selector(forwardingTargetForSelector:),
                                                                                        delegateBlock);
                    }
                    
                    BDDelegateDecorator *delegateDecorator = [BDDelegateDecorator decoratorForDelegate:delegate];
                    BDTableViewDelegateDecorator *decorator = [[BDTableViewDelegateDecorator alloc] initWithTarget:delegate];
                    [delegateDecorator setDecorator:decorator forSelector:didSelectItemSelector];
                }
                
                ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
            }
        });
    });
}

@end
