//
//  BDAutoTrackApplication.h
//  RangersAppLog
//
//  Created by bytedance on 2022/4/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"

// screen orientation
static NSString * const kBDAutoTrackPortrait = @"portrait";
static NSString * const kBDAutoTrackLandscape = @"landscape";

// gps
static NSString * const kBDAutoTrackWGS84 = @"WGS84";
static NSString * const kBDAutoTrackGCJ02 = @"GCJ02";
static NSString * const kBDAutoTrackBD09 = @"BD09";
static NSString * const kBDAutoTrackBDCS = @"BDCS";


@interface BDAutoTrackApplication : NSObject

// screen orientation
@property (nonatomic, strong) NSString *screenOrientation;

// gps
@property (nonatomic, strong) NSString *geoCoordinateSystem;
@property (nonatomic, assign) long longitude;
@property (nonatomic, assign) long latitude;

// autotrack gps
@property (nonatomic, strong) NSString *autoTrackGeoCoordinateSystem;
@property (nonatomic, assign) long autoTrackLongitude;
@property (nonatomic, assign) long autoTrackLatitude;

+ (instancetype)shared;

// gps
- (void)updateGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude;
- (BOOL)hasGPSLocation;

// autotrack gps
- (void)updateAutoTrackGPSLocation:(enum BDAutoTrackGeoCoordinateSystem)geoCoordinateSystem longitude:(double)longitude latitude:(double)latitude;
- (BOOL)hasAutoTrackGPSLocation;

@end

