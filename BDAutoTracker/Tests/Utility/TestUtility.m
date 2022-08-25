//
//  TestUtility.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/9.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackUtility.h"
#import "NSDictionary+VETyped.h"
@interface TestUtility : XCTestCase

@end

@implementation TestUtility

- (void)testFormatter {
    NSDate *now = [NSDate new];

    NSString *dateString = [bd_dateFormatter() stringFromDate:now];
    NSString *todayString = [bd_dayFormatter() stringFromDate:now];
    XCTAssertNotNil(dateString);
    XCTAssertNotNil(todayString);
    XCTAssertEqualObjects(todayString, bd_dateTodayString());
    XCTAssertEqualObjects(dateString, bd_dateNowString());
    XCTAssertTrue([dateString containsString:todayString]);

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute | NSCalendarUnitHour | kCFCalendarUnitSecond
                                                                   fromDate:now];
    NSInteger hour = components.hour;
    NSInteger minute = components.minute;
    NSInteger second =components.second;

    CFTimeInterval intervalToday =  second + minute * 60.0 + hour * 3600.0;
    CFTimeInterval intervalTodayLeft =  24 * 3600.0 - intervalToday;

    NSString *todayString1 = [bd_dayFormatter() stringFromDate:[now dateByAddingTimeInterval:intervalTodayLeft -1]];
    XCTAssertEqualObjects(todayString, todayString1);
    NSString *todayString2 = [bd_dayFormatter() stringFromDate:[now dateByAddingTimeInterval: - intervalToday + 1]];
    XCTAssertEqualObjects(todayString, todayString2);

    NSString *todayString3 = [bd_dayFormatter() stringFromDate:[now dateByAddingTimeInterval: intervalTodayLeft + 1]];
    XCTAssertNotEqualObjects(todayString, todayString3);
    NSString *todayString4 = [bd_dayFormatter() stringFromDate:[now dateByAddingTimeInterval: - intervalToday - 1]];
    XCTAssertNotEqualObjects(todayString, todayString4);
}

- (void)testDictionary {
    NSDictionary *param = @{@"Test1":@"1",
                            @"Test2":@(2),
                            @"Test3":@(false),
                            };
    
    XCTAssertTrue([param vetyped_boolForKey:@"Test1"]);
    XCTAssertTrue([param vetyped_boolForKey:@"Test2"]);
    XCTAssertFalse([param vetyped_boolForKey:@"Test3"]);
    XCTAssertFalse([param vetyped_boolForKey:@"Test4"]);


    XCTAssertEqual([param vetyped_integerForKey:@"Test1"], 1);
    XCTAssertEqual([param vetyped_integerForKey:@"Test2"], 2);
    XCTAssertEqual([param vetyped_longlongValueForKey:@"Test1"], 1);
    XCTAssertEqual([param vetyped_longlongValueForKey:@"Test2"], 2);

    XCTAssertEqual([param vetyped_integerForKey:@"Test3"], 0);

    XCTAssertEqualObjects([param vetyped_stringForKey:@"Test1"],@"1");
    XCTAssertEqualObjects([param vetyped_stringForKey:@"Test2"],@"2");
    XCTAssertEqualObjects([param vetyped_stringForKey:@"Test3"],@"0");

    XCTAssertNil([param vetyped_arrayForKey:@"Test01"]);
    XCTAssertNil([param vetyped_dictionaryForKey:@"Test01"]);
}

- (void)testUUID {
    NSString *uuid1 = bd_UUID();
    NSString *uuid2 = bd_UUID();
    XCTAssertNotEqualObjects(uuid1, uuid2);
}

- (void)testInterval {
    XCTestExpectation *expectation = [self expectationWithDescription:@"interval"];
    NSNumber *interval11 = bd_currentInterval();
    NSTimeInterval interval12 = bd_currentIntervalValue();
    /// 会有误差
    XCTAssertEqualWithAccuracy(interval11.doubleValue, interval12, 0.2);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSNumber *interval21 = bd_currentInterval();
        NSTimeInterval interval22 = bd_currentIntervalValue();
        XCTAssertEqualWithAccuracy(interval21.doubleValue, interval22, 0.2);

        /// dispatch_after 1s不准确，误差
        XCTAssertEqualWithAccuracy(interval21.doubleValue, interval11.doubleValue, 1.4);
        XCTAssertEqualWithAccuracy(interval12, interval22, 1.4);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:2.3];
}

- (void)testQueryFromDictionary {
    NSString *all = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "; ///
    all = @"\"#%<>[\\]^`{|}"; /// query allowed
    __block NSInteger index = 1;
    NSMutableDictionary<NSString *, NSString *> *param = [NSMutableDictionary new];
    [all enumerateSubstringsInRange:NSMakeRange(0, all.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [param setValue:substring forKey:[NSString stringWithFormat:@"Test_%zd", index++]];
    }];

    NSString *queryFromDictionary = bd_queryFromDictionary(param);
    [param.allValues enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL *stop) {
        XCTAssertFalse([queryFromDictionary containsString:obj] && ![obj isEqualToString:@"%"]);
    }];
}

- (NSArray<NSString *> *)addressOfObjectsInA:(NSArray *)a {
    NSMutableArray<NSString *> *address = [NSMutableArray new];
    [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [address addObject:[NSString stringWithFormat:@"%p", obj]];
        if ([obj isKindOfClass:[NSArray class]]) {
            [address addObjectsFromArray:[self addressOfObjectsInA:obj]];
        }
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [address addObjectsFromArray:[self addressOfObjectsInD:obj]];
        }
        if ([obj isKindOfClass:[NSSet class]]) {
            NSSet *set = (NSSet *)obj;
            [address addObjectsFromArray:[self addressOfObjectsInA:set.allObjects]];
        }
    }];

    return address;
}

- (NSArray<NSString *> *)addressOfObjectsInD:(NSDictionary *)a {
    NSMutableArray<NSString *> *address = [NSMutableArray new];
    [a.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [address addObject:[NSString stringWithFormat:@"%p", obj]];
        if ([obj isKindOfClass:[NSArray class]]) {
            [address addObjectsFromArray:[self addressOfObjectsInA:obj]];
        }
        if ([obj isKindOfClass:[NSSet class]]) {
            NSSet *set = (NSSet *)obj;
            [address addObjectsFromArray:[self addressOfObjectsInA:set.allObjects]];
        }
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [address addObjectsFromArray:[self addressOfObjectsInD:obj]];
        }
    }];

    return address;
}

- (void)testDeepCopy {
    NSDictionary *param = @{@"Test1":@"1",
                            @"Test2":@"2",/// @(2) will not mutable copy
                            @"Test3":@{
                                    @"Test31":@"Test",
                                    @"Test32":@"Test"
                                    },
                            @"Test4":@[@"11",@"12",@"13"],
                            @"Test5": @100,
                            @"Test6": @3.14
                            };
    NSDictionary *copyed = bd_trueDeepCopyOfDictionary(param);
    NSArray<NSString *> *address = [self addressOfObjectsInD:param];
    NSArray<NSString *> *addressCopy = [self addressOfObjectsInD:copyed];
    [address enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertFalse([addressCopy containsObject:obj]);
    }];
}

- (void)testPath {
    XCTAssertEqualObjects(bd_trackerLibraryPath(), bd_trackerLibraryPath());
    NSString *appid = @"1111";
    NSString *path = bd_trackerLibraryPathForAppID(appid);
    XCTAssertTrue([path containsString:appid]);
    XCTAssertTrue([path containsString:@"._tob_applog_docu"]);  // 数据库文件夹名字
    XCTAssertTrue([path containsString:@"Library"]);  // 在Library目录下
    XCTAssertFalse([path containsString:@"Caches"]);  // 不在Caches目录下
    
    NSString *appid2 = @"1112";
    NSString *path2 = bd_trackerLibraryPathForAppID(appid2);
    XCTAssertNotEqualObjects(path, path2);

    BOOL isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path2 isDirectory:&isDir]);
    XCTAssertTrue(isDir);
}

- (void)testPathCreate {
    XCTAssertEqualObjects(bd_trackerLibraryPath(), bd_trackerLibraryPath());
    NSString *appid = @"1111";
    NSString *path = bd_trackerLibraryPathForAppID(appid);
    XCTAssertTrue([path containsString:appid]);
    XCTAssertTrue([path containsString:@"._tob_applog_docu"]);
    XCTAssertTrue([path containsString:@"Library"]);

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    bd_trackerLibraryPathForAppID(appid);
    BOOL isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    NSData *test = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    [[NSFileManager defaultManager] createFileAtPath:path contents:test attributes:nil];
    bd_trackerLibraryPathForAppID(appid);
    isDir = NO;
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]);
    XCTAssertTrue(isDir);
}

- (void)testJSON {
    NSDictionary *param = @{@"test":@"test"};
    NSString *json = bd_JSONRepresentation(param);
    XCTAssertNotNil(json);
    XCTAssertEqualObjects(json, bd_JSONRepresentation(param));

    id object = bd_JSONValueForString(json);
    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object, param);

    XCTAssertNil(bd_JSONRepresentation(@""));
    XCTAssertNil(bd_JSONRepresentation(@{@(1):@"test"}));

    XCTAssertNil(bd_JSONValueForString(@""));
    XCTAssertNil(bd_JSONValueForString(nil));
}

@end
