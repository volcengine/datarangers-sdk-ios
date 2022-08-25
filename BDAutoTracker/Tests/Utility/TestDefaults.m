//
//  TestDefaults.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackDefaults.h"

@interface BDAutoTrackDefaults (Test)
- (instancetype)initWithAppID:(NSString *)appID;
@end

@interface TestDefaults : XCTestCase

@property (nonatomic, strong) BDAutoTrackDefaults *defaults;
@property (nonatomic, strong) BDAutoTrackDefaults *namedDefaults;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *defaultsName;

@end

@implementation TestDefaults

- (void)setUp {
    self.appID = @"0";
    self.defaultsName = @"test.plist";
    self.defaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID];
    self.namedDefaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID name:self.defaultsName];
    [self.defaults clearAllData];
    [self.namedDefaults clearAllData];
}

- (void)testReadNilValue {
    XCTAssertNil([self.defaults stringValueForKey:@"Test"]);
    XCTAssertNil([self.namedDefaults stringValueForKey:@"Test"]);
}

- (void)testReadValue {
    [self.defaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.defaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.defaults stringValueForKey:@"TestValue"], @"TestValue");

    [self.namedDefaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.namedDefaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.namedDefaults stringValueForKey:@"TestValue"], @"TestValue");
}

- (void)testSaveNilValue {
    [self.defaults setValue:nil forKey:@"TestValue"];
    XCTAssertNil([self.defaults stringValueForKey:@"TestValue"]);

    [self.namedDefaults setValue:nil forKey:@"TestValue"];
    XCTAssertNil([self.namedDefaults stringValueForKey:@"TestValue"]);
}

- (void)testSaveFile {
    [self.defaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.defaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.defaults stringValueForKey:@"TestValue"], @"TestValue");
    [self.defaults saveDataToFile];

    BDAutoTrackDefaults *defaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID];
    XCTAssertEqualObjects([defaults stringValueForKey:@"TestValue"], @"TestValue");

    [self.namedDefaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.namedDefaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.namedDefaults stringValueForKey:@"TestValue"], @"TestValue");
    [self.namedDefaults saveDataToFile];

    BDAutoTrackDefaults *namedDefaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID name:self.defaultsName];
    XCTAssertEqualObjects([namedDefaults stringValueForKey:@"TestValue"], @"TestValue");
}

- (void)testClearData {
    [self.defaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.defaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.defaults stringValueForKey:@"TestValue"], @"TestValue");
    [self.defaults clearAllData];
    
    XCTAssertNil([self.defaults stringValueForKey:@"TestValue"]);
    BDAutoTrackDefaults *defaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID];
    XCTAssertNil([defaults stringValueForKey:@"TestValue"]);

    [self.namedDefaults setValue:@"TestValue" forKey:@"TestValue"];
    XCTAssertNotNil([self.namedDefaults stringValueForKey:@"TestValue"]);
    XCTAssertEqualObjects([self.namedDefaults stringValueForKey:@"TestValue"], @"TestValue");
    [self.namedDefaults clearAllData];

    XCTAssertNil([self.namedDefaults stringValueForKey:@"TestValue"]);
    BDAutoTrackDefaults *namedDefaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID name:self.defaultsName];
    XCTAssertNil([namedDefaults stringValueForKey:@"TestValue"]);
}

- (void)testValues {
    NSString *key = @"testValues";
    BDAutoTrackDefaults *defaults = [[BDAutoTrackDefaults alloc] initWithAppID:self.appID];
    [defaults setValue:@1.0 forKey:key];
    XCTAssertEqualWithAccuracy([defaults doubleValueForKey:key], 1.0, 0.01);

    [defaults setValue:@1 forKey:key];
    XCTAssertEqual([defaults integerValueForKey:key], 1);

    [defaults setValue:@{@"test":@"test"} forKey:key];
    XCTAssertEqualObjects([defaults dictionaryValueForKey:key], @{@"test":@"test"});
    [defaults setValue:@[@"test",@"test1"] forKey:key];
    NSArray *test = @[@"test",@"test1"];
    XCTAssertEqualObjects([defaults arrayValueForKey:key],test);
}

@end
