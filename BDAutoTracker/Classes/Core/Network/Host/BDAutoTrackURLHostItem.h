//
//  BDAutoTrackURLHostItem.h
//  RangersAppLog
//
//  Created by bob on 2020/8/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackURLHostItemProtocol.h"
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackURLHostItem : NSObject<BDAutoTrackURLHostItemProtocol>

- (nullable BDAutoTrackServiceVendor)vendor;
- (NSString *)URLPathForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)URLForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)URLHostForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)thirdLevelDomainForURLType:(BDAutoTrackRequestURLType)type;
- (nullable NSString *)hostDomain;

@end

NS_ASSUME_NONNULL_END
