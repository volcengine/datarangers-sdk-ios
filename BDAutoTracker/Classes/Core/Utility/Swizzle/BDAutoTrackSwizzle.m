//
//  BDAutoTrackSwizzle.m
//  Applog
//
//  Created by bob on 2019/1/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSwizzle.h"

IMP bd_swizzle_class_methodWithBlock(Class cls, SEL originalSelector, id block) {
    Class metaClass = object_getClass(cls);
    Method origMethod = class_getClassMethod(metaClass, originalSelector);
    const char *types = method_getTypeEncoding(origMethod);
    IMP newIMP = imp_implementationWithBlock(block);
    IMP oldIMP = method_getImplementation(origMethod);

    BOOL didAddMethod = class_addMethod(metaClass, originalSelector, newIMP , types);

    /// if supper has but self doesn't have
    if (!didAddMethod) {
        /// self has method
        class_replaceMethod(metaClass, originalSelector, newIMP, types);
    }

    return oldIMP;
}

IMP bd_swizzle_instance_methodWithBlock(Class c, SEL origSEL, id block) {
    NSCParameterAssert(block);
    Method origMethod = class_getInstanceMethod(c, origSEL);
    NSCParameterAssert(origMethod);
    const char *types = method_getTypeEncoding(origMethod);
    IMP newIMP = imp_implementationWithBlock(block);
    IMP oldIMP = method_getImplementation(origMethod);

    BOOL didAddMethod = class_addMethod(c, origSEL, newIMP, types);
    if (!didAddMethod) {
        /// self has method
        class_replaceMethod(c, origSEL, newIMP, types);
    }

    return oldIMP;
}

void bd_swizzle_replace(Class cls, SEL originalSEL, SEL alterSEL, BOOL isClassMethod)
{
    Method alterMethod = (isClassMethod
                                        ? class_getClassMethod(cls, alterSEL)
                                        : class_getInstanceMethod(cls, alterSEL));
    Class targetClass = (isClassMethod
                         ? object_getClass(cls)
                         : cls);
    class_replaceMethod(targetClass,
                        originalSEL,
                        method_getImplementation(alterMethod),
                        method_getTypeEncoding(alterMethod));
}

/// 就是给一个类加新方法 不是swizzle
BOOL bd_swizzle_instance_addMethod(Class target, SEL aSelector, Class source) {
    NSCParameterAssert(aSelector);
    Method origMethod = class_getInstanceMethod(source, aSelector);
    NSCParameterAssert(origMethod);
    const char *types = method_getTypeEncoding(origMethod);
    IMP methodIMP = method_getImplementation(origMethod);

    return class_addMethod(target, aSelector, methodIMP, types);
}

BOOL bd_swizzle_has_selector(id delegate, SEL aSelector) {
    NSCParameterAssert(delegate);
    NSCParameterAssert(aSelector);
    Class target = object_getClass(delegate);
    NSCParameterAssert(target);
    Method origMethod = class_getInstanceMethod(target, aSelector);
    
    return origMethod != nil;
}

@implementation BDAutoTrackSwizzle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.originIMP = NULL;
    }
    
    return self;
}

- (void)dealloc {
    self.originIMP = NULL;
}

@end
