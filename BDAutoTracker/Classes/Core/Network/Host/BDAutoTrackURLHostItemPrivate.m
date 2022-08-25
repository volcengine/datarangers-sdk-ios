//
//  BDAutoTrackURLHostItemPrivate.m
//  RangersAppLog
//
//  Created by bob on 2020/8/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackURLHostItemPrivate.h"

BDAutoTrackServiceVendor const BDAutoTrackServiceVendorPrivate  = @"private";

@implementation BDAutoTrackURLHostItemPrivate

- (BDAutoTrackServiceVendor)vendor {
    return BDAutoTrackServiceVendorPrivate;
}

- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type {
    return nil;
}

@end
