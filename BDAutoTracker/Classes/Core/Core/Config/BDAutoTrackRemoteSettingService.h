//
//  BDAutoTrackRemoteSettingService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN



@interface BDAutoTrackRemoteSettingService : BDAutoTrackService

@property (nonatomic, assign, readonly) NSTimeInterval batchInterval;
@property (nonatomic, assign, readonly) NSUInteger batchBulkSize;
@property (nonatomic, assign, readonly) NSTimeInterval abFetchInterval;
@property (nonatomic, assign) BOOL abTestEnabled;
@property (nonatomic, assign) BOOL autoTrackEnabled;
@property (nonatomic, assign, readonly) BOOL skipLaunch;
@property (atomic, copy, readonly) NSArray *realTimeEvents;
@property (nonatomic, assign) NSInteger fetchInterval;

@property (atomic, copy, readonly ) NSArray *sensitiveFields;  

- (instancetype)initWithAppID:(NSString *)appID;
- (void)updateRemoteWithResponse:(NSDictionary *)responseDict;

- (NSDictionary *)devtools_toDictionary;

@end

FOUNDATION_EXTERN BDAutoTrackRemoteSettingService *_Nullable bd_remoteSettingsForAppID(NSString *appID);


NS_ASSUME_NONNULL_END
