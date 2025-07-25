//
//  BDAutoTrackConfig+AppLog.h
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackConfig.h"
#import "BDCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackConfig (AppLog)

@property (nonatomic, assign) BOOL trackEventEnabled;

@property (nonatomic, assign) BOOL autoTrackEnabled;

@property (nonatomic, assign) BDAutoTrackDataType autoTrackEventType;

@property (nonatomic) BOOL H5AutoTrackEnabled;

@property (nonatomic) BOOL screenOrientationEnabled;

@property (nonatomic) BOOL trackGPSLocationEnabled;

@property (nonatomic, assign) BOOL showDebugLog;

@property (nonatomic, copy, nullable) BDAutoTrackLogger logger;

@property (nonatomic, assign) BOOL logNeedEncrypt;
@property (nonatomic, assign) BOOL logResponseNeedEncrypt;
@property (nonatomic, assign) BOOL logReportOptimizeEnabled;

@property (nonatomic, assign) BOOL autoFetchSettings;

@property (nonatomic, assign) BOOL abEnable;

@property (nonatomic, assign) BOOL launchTerminateEnable;

@property (nonatomic, copy) BDAutoTrackMockBlock mockVendorIDBlock;

@property (nonatomic, copy) BDAutoTrackMockBlock mockAdvertisingIDBlock;

@end

NS_ASSUME_NONNULL_END
