//
//  BDAutoTrackIdentifier.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/10/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackIdentifier.h"
#import "BDAutoTrackDeviceHelper.h"
#import "RangersAppLogConfig.h"
#import "BDAutoTrack+Private.h"

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackLocalConfigService.h"

@interface BDAutoTrackIdentifier ()

@property (nonatomic, weak) BDAutoTrack *tracker;

@end

@implementation BDAutoTrackIdentifier

- (instancetype)initWithTracker:(id)tracker
{
    self = [super init];
    if (self) {
        self.tracker = tracker;
    }
    return self;
}


- (NSString *)mock_vendorID
{
    static NSString *mock_vendorID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mock_vendorID = [NSUUID UUID].UUIDString;
    });
    return mock_vendorID;
}

- (NSString *)vendorID
{
    if (self.mockEnabled) {
        if (self.tracker.config.mockVendorIDBlock) {
            return self.tracker.config.mockVendorIDBlock();
        }
        return [self mock_vendorID];
    }
    return bd_device_IDFV();
}

- (NSString *)mock_advertisingID
{
    static NSString *mock_advertisingID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mock_advertisingID = [NSUUID UUID].UUIDString;
    });
    return mock_advertisingID;
}

- (NSString *)advertisingID
{
    if (self.mockEnabled) {
        if (self.tracker.config.mockAdvertisingIDBlock) {
            return self.tracker.config.mockAdvertisingIDBlock();
        }
        return [self mock_advertisingID];
    }
    return [[RangersAppLogConfig sharedInstance].handler uniqueID];
}


- (void)clearIDs
{
    BDAutoTrackDefaults *defaults = [BDAutoTrackDefaults defaultsWithAppID:self.tracker.appID];
    [defaults clearAllData];
}

- (NSString *)suffixedKey:(NSString *)key {
    
    BDAutoTrackServiceVendor vendor = self.serviceVendor;
    if (vendor && vendor.length > 0) {
        key = [key stringByAppendingFormat:@"_%@", vendor];
    }
    return key;
}


- (BOOL)isAuthorized
{
    return [[RangersAppLogConfig sharedInstance].handler isAuthorized];
}


@end
