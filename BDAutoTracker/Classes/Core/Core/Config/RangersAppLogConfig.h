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

@end

/// 自己用的单例类，存放一些属性
@interface RangersAppLogConfig : NSObject

/// 默认为
@property (nonatomic, copy, nullable) BDAutoTrackServiceVendor defaultVendor;
@property (atomic, strong) id<BDAutoTrackUniqueIDHandler> handler;
/// 是否已连接到服务器圈选
@property (nonatomic, assign, getter=isSeversidePickerAvailable) BOOL seversidePickerAvailable;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
