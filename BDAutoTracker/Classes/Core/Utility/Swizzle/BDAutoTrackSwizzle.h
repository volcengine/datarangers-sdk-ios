//
//  BDAutoTrackSwizzle.h
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

// swizzle 类的类方法，即 +方法
FOUNDATION_EXTERN IMP bd_swizzle_class_methodWithBlock(Class cls, SEL originalSelector, id block);

// swizzle 类的实例方法 即 -方法
FOUNDATION_EXTERN IMP bd_swizzle_instance_methodWithBlock(Class c, SEL origSEL, id block);
FOUNDATION_EXTERN BOOL bd_swizzle_instance_addMethod(Class target, SEL aSelector, Class source);
FOUNDATION_EXTERN BOOL bd_swizzle_has_selector(id delegate, SEL aSelector);


FOUNDATION_EXTERN void bd_swizzle_replace(Class cls, SEL original, SEL alternative, BOOL isClassMethod);


@interface BDAutoTrackSwizzle : NSObject

@property (nonatomic, assign, nullable) IMP originIMP;

@end

NS_ASSUME_NONNULL_END
