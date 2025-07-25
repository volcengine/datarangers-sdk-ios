//
//  RangersAppLogConfig.h
//  RangersAppLog
//
//  Created by bob on 2020/5/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDAutoTrackUniqueIDHandler <NSObject>

- (NSString *)uniqueID;
- (BOOL)isAuthorized;

@end

@interface RangersAppLogConfig : NSObject

@property (nonatomic, copy, nullable) BDAutoTrackServiceVendor defaultVendor;
@property (atomic, strong) id<BDAutoTrackUniqueIDHandler> handler;
@property (nonatomic, assign, getter=isSeversidePickerAvailable) BOOL seversidePickerAvailable;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
