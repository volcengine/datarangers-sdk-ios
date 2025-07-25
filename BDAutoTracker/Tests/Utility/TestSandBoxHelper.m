//
//  TestSandBoxHelper.m
//  BDAutoTracker_Tests
//
//  Created by bob on 2019/9/14.
//  Copyright © 2019 ByteDance. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "BDAutoTrackSandBoxHelper.h"

@interface TestSandBoxHelper : XCTestCase

@property (strong, nonatomic) id bundleMock;

@end

@implementation TestSandBoxHelper

- (void)testAppVersion {
    NSString *appVersion = bd_sandbox_buildVersion();
    NSString *appVersionEx = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
    XCTAssertEqualObjects(appVersion, appVersionEx);

    NSString *appShortVersion = bd_sandbox_releaseVersion();
    NSString *appShortVersionEx = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
    XCTAssertEqualObjects(appShortVersion, appShortVersionEx);
}

- (void)testAppIdentifier {
}

- (void)testUA {
    XCTAssertNotNil(bd_sandbox_userAgent());
}

- (void)testUserUpgrade1 {
    NSString *key = @"kAppLogInstallAppVersion";
    NSString *preAppVersion = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    NSString *versionName = bd_sandbox_releaseVersion();
    BOOL isUpgradeUser = preAppVersion.length > 1 && ![preAppVersion isEqualToString:versionName];
    XCTAssertEqual(bd_sandbox_isUpgradeUser(), isUpgradeUser);
}

@end
