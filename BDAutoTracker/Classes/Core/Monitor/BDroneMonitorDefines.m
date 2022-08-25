//
//  BDroneMonitorDefines.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDroneMonitorDefines.h"


BDroneMonitorCategory const BDroneNetworkCategory = @"network_service";    //网络

BDroneMonitorMetricsName const BDroneNetworkLogSetting              = @"log_settings";
BDroneMonitorMetricsName const BDroneNetworkDeviceRegistration      = @"device_register";
BDroneMonitorMetricsName const BDroneNetworkDeviceActivation        = @"app_alert_check";
BDroneMonitorMetricsName const BDroneNetworkProfile                 = @"profile";
BDroneMonitorMetricsName const BDroneNetworkABTest                  = @"abtest_config";
BDroneMonitorMetricsName const BDroneNetworkALinkDeepLink           = @"alink_data";
BDroneMonitorMetricsName const BDroneNetworkALinkDeferredDeepLink   = @"attribution_data";


BDroneMonitorCategory const BDroneUsageCategory = @"sdk_usage";

BDroneMonitorMetricsName const BDroneUsageInitialization = @"sdk_init";
BDroneMonitorMetricsName const BDroneUsageStartup = @"sdk_startup";
BDroneMonitorMetricsName const BDroneUsageDataUploadDelay = @"db_delay_interval";
BDroneMonitorMetricsName const BDroneUsageAPI = @"api_calls";


BDroneMonitorCategory const BDroneTrackCategory = @"data_statistics";

BDroneMonitorMetricsName const BDroneTrackEventVolume = @"api_calls";
BDroneMonitorMetricsName const BDroneTrackDatabaseException = @"db_exception";


