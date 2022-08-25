//
//  TestDeviceHelper.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/14.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BDAutoTrackDeviceHelper.h"
#import "sys/utsname.h"
#import <AdSupport/AdSupport.h>

@interface TestDeviceHelper : XCTestCase

@end

@implementation TestDeviceHelper

- (void)testExample {

    NSString *localeIdentifier = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
    NSString *systemLanguage = [languageDic objectForKey:NSLocaleLanguageCode];
    XCTAssertEqual(bd_device_currentSystemLanguage(), systemLanguage);

    NSString *platformName = [UIDevice currentDevice].model.lowercaseString;
    XCTAssertEqualObjects(bd_device_platformName(), platformName);

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float scale = [[UIScreen mainScreen] scale];

    XCTAssertEqualWithAccuracy(scale, bd_device_screenScale(), 0.001);

    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    NSString *resolutionString = [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
    XCTAssertEqualObjects(bd_device_resolutionString(), resolutionString);

    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    XCTAssertEqualObjects(bd_device_systemVersion(), systemVersion);
}


@end
