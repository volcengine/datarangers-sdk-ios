//
//  BDAutoTrackDelegateSwizzle.h
//  Pods
//
//  Created by bytedance on 2023/9/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackDelegateForwardData : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) id forwardTarget;

- (instancetype)initWithDelegate:(id)delegate forwardTarget:(id)forwardTarget;
- (id)target;

@end


@interface BDAutoTrackDelegateIMP : NSObject

@property (nonatomic, weak, readonly) id delegate;

- (instancetype)initWithDelegate:(id)delegate;
- (void)save:(IMP)imp selector:(SEL)selector;
- (IMP)load:(SEL)selector;

@end


typedef void (^bdautotrack_delegate_swizzle_block)(id delegate);
typedef id _Nullable (^bdautotrack_delegate_decorator_block)(BDAutoTrackDelegateForwardData *delegateForwardData);
typedef void (^bdautotrack_delegate_noselector_block)(id delegate);


@interface BDAutoTrackDelegateSwizzle : NSObject

- (instancetype)initWithTarget:(Class)targetClass;

- (void)markWith:(SEL)selector markerClass:(Class)markerClass;

- (void)delegateSelector:(SEL)selector
            swizzleBlock:(bdautotrack_delegate_swizzle_block)swizzleBlock
          decoratorBlock:(bdautotrack_delegate_decorator_block)decoratorBlock
         noselectorBlock:(bdautotrack_delegate_noselector_block)noselectorBlock;

- (void)swizzleDelegate;

- (void)save:(IMP)imp selector:(SEL)selector forDelegate:(id)delegate;

- (IMP)load:(SEL)selector forDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
