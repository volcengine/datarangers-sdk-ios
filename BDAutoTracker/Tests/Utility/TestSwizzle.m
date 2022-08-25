//
//  TestSwizzle.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/11.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackSwizzle.h"

@interface TestClass : NSObject

@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, assign) NSInteger callCount;

- (void)instanceMethod;
+ (void)classMethodWithObject:(TestClass *)object;

@end

@implementation TestClass

- (void)instanceMethod {
    self.callCount++;
}

+ (void)classMethodWithObject:(TestClass *)object {
    object.callCount++;
}

@end

@interface TestSubClass : TestClass

@end

@implementation TestSubClass

@end

static void bd_unswizzle_instance_methodWithImp(Class c, SEL origSEL,IMP newIMP) {
    Method origMethod = class_getInstanceMethod(c, origSEL);
    NSCParameterAssert(origMethod);
    method_setImplementation(origMethod, newIMP);
}

static void bd_unswizzle_class_methodWithImp(Class cls, SEL originalSelector, IMP newIMP) {
    Class metaClass = object_getClass(cls);
    Method origMethod = class_getClassMethod(metaClass, originalSelector);
    method_setImplementation(origMethod, newIMP);
}


@interface TestSwizzle : XCTestCase

@end

@implementation TestSwizzle

- (void)testSubInstanceMethod {
    static IMP imp = nil;
    TestSubClass *test = [TestSubClass new];
    test.callCount = 0;
    XCTAssertEqual(test.callCount, 0);
    [test instanceMethod];
    XCTAssertEqual(test.callCount, 1);
    imp = bd_swizzle_instance_methodWithBlock([TestSubClass class], @selector(instanceMethod), ^(TestSubClass *_self){
        _self.callCount++;
        XCTAssertEqual(_self.callCount, 2);

        if (imp) {
            ((void ( *)(id, SEL))imp)(_self, @selector(instanceMethod));
        }
        XCTAssertEqual(_self.callCount, 3);
    });
    [test instanceMethod];
    bd_unswizzle_instance_methodWithImp([TestSubClass class], @selector(instanceMethod), imp);
    XCTAssertEqual(test.callCount, 3);
}

- (void)testInstanceMethod {
    static IMP imp = nil;
    TestClass *test = [TestClass new];
    test.callCount = 0;
    XCTAssertEqual(test.callCount, 0);
    [test instanceMethod];
    XCTAssertEqual(test.callCount, 1);
    imp = bd_swizzle_instance_methodWithBlock([TestClass class], @selector(instanceMethod), ^(TestClass *_self){
        _self.callCount++;
        XCTAssertEqual(_self.callCount, 2);

        if (imp) {
            ((void ( *)(id, SEL))imp)(_self, @selector(instanceMethod));
        }
        XCTAssertEqual(_self.callCount, 3);
    });
    [test instanceMethod];
    bd_unswizzle_instance_methodWithImp([TestClass class], @selector(instanceMethod), imp);
    XCTAssertEqual(test.callCount, 3);
}

- (void)testSubClassMethod {
    static IMP imp = nil;
    TestSubClass *test = [TestSubClass new];
    test.callCount = 0;
    XCTAssertEqual(test.callCount, 0);
    [TestSubClass classMethodWithObject:test];
    XCTAssertEqual(test.callCount, 1);
    imp = bd_swizzle_class_methodWithBlock([TestSubClass class], @selector(classMethodWithObject:), ^(Class _self, TestSubClass *object){
        object.callCount++;
        XCTAssertEqual(object.callCount, 2);

        if (imp) {
            ((void ( *)(Class, SEL, id))imp)(_self, @selector(classMethodWithObject:), object);
        }
        XCTAssertEqual(object.callCount, 3);
    });
    [TestSubClass classMethodWithObject:test];
    bd_unswizzle_class_methodWithImp([TestSubClass class], @selector(classMethodWithObject:), imp);
    XCTAssertEqual(test.callCount, 3);
}

- (void)testClassMethod {
    static IMP imp = nil;
    TestClass *test = [TestClass new];
    test.callCount = 0;
    XCTAssertEqual(test.callCount, 0);
    [TestClass classMethodWithObject:test];
    XCTAssertEqual(test.callCount, 1);
    imp = bd_swizzle_class_methodWithBlock([TestClass class], @selector(classMethodWithObject:), ^(Class _self, TestClass *object){
        object.callCount++;
        XCTAssertEqual(object.callCount, 2);

        if (imp) {
            ((void ( *)(Class, SEL, id))imp)(_self, @selector(classMethodWithObject:), object);
        }
        XCTAssertEqual(object.callCount, 3);
    });
    [TestClass classMethodWithObject:test];
    bd_unswizzle_class_methodWithImp([TestClass class], @selector(classMethodWithObject:), imp);
    XCTAssertEqual(test.callCount, 3);
}

@end
