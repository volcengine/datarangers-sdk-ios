//
//  TestTimer.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackTimer.h"

@interface TestTimer : XCTestCase

@end

@implementation TestTimer

- (void)testTimerWithRepeatInterval {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimerWithRepeatInterval"];
    expectation.expectedFulfillmentCount = 6;
    NSTimeInterval interval = 0.6;
    __block NSInteger index = 0;

    dispatch_block_t action = ^{
        index++;
        XCTAssertLessThan(index, 7);
        /// should cancel it to release the action
        if (index == 6) {
            [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:@"Repeat"];
        }
        [expectation fulfill];
    };
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:@"Repeat"
                                                         timeInterval:interval
                                                                queue:nil
                                                              repeats:YES
                                                               action:action];
    /// timeout should be inside a interval
    CFTimeInterval timeout = expectation.expectedFulfillmentCount * interval;
    [self waitForExpectations:@[expectation] timeout:timeout + 0.3];
}

- (void)testTimerWithNoRepeatInterval {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimerWithNoRepeatInterval"];
    NSTimeInterval interval = 0.1;
    __block NSInteger index = 0;
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:@"NoRepeat"
                                                         timeInterval:interval
                                                                queue:dispatch_get_main_queue()
                                                              repeats:NO
                                                               action:^{
                                                                   [expectation fulfill];
                                                                   index++;
                                                                   XCTAssertLessThan(index, 2);
                                                               }];

    [self waitForExpectations:@[expectation] timeout:2 * interval + 0.3];
}

- (void)testTimerWithCancel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testTimerWithCancel"];
    NSTimeInterval interval = 0.1;
    __block NSInteger index = 0;
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:@"Cancel"
                                                         timeInterval:interval
                                                                queue:nil
                                                              repeats:NO
                                                               action:^{
                                                                   index++;
                                                                   XCTAssertLessThan(index, 1);
                                                               }];
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:@"Cancel"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((interval + 0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertLessThan(index, 1);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:2 * interval + 0.3];
}

- (void)testInvalidateInterval {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInvalidate"];
    NSTimeInterval interval = 0.00001f;
    __block NSInteger index = 0;
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:@"Cancel"
                                                         timeInterval:interval
                                                                queue:nil
                                                              repeats:NO
                                                               action:^{
                                                                   index++;
                                                                   XCTAssertLessThan(index, 1);
                                                               }];
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:@"Cancel"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((interval + 0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertLessThan(index, 1);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:2 * interval + 0.3];
}

- (void)testInvalidateName {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInvalidateName"];
    NSTimeInterval interval = 0.1f;
    __block NSInteger index = 0;
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:nil
                                                         timeInterval:interval
                                                                queue:nil
                                                              repeats:NO
                                                               action:^{
                                                                   index++;
                                                                   XCTAssertLessThan(index, 1);
                                                               }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((interval + 0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertLessThan(index, 1);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:2 * interval + 0.3];
}

- (void)testInvalidateAction {
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:@"testInvalidateAction"
                                                         timeInterval:0.1
                                                                queue:nil
                                                              repeats:NO
                                                               action:nil];
}

@end
