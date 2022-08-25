//
//  BDAutoTrackURLHostProtocol.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/5.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// to provide host URLs for a specific vendor
@protocol BDAutoTrackURLHostItemProtocol <NSObject>

@required

- (nullable BDAutoTrackServiceVendor)vendor;
- (NSString *)URLPathForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)URLForURLType:(BDAutoTrackRequestURLType)type;

@optional

- (nullable NSString *)URLHostForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)thirdLevelDomainForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)hostDomain;

@end

NS_ASSUME_NONNULL_END
