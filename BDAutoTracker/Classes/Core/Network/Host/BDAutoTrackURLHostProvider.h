//
//  BDAutoTrackURLHostProvider.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/8/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"
#import "BDAutoTrackURLHostItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// to provide URL host for network request
/// format like: https://gist.github.com/
@interface BDAutoTrackURLHostProvider : NSObject

+ (instancetype)sharedInstance;

/// to provide URL Host Based on request URL type and vendor region
/// @param type request URL type
/// @param appID appID
- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type
                      appID:(NSString *)appID;

- (BOOL)registerHostItem:(id<BDAutoTrackURLHostItemProtocol>)hostItem;

@end

NS_ASSUME_NONNULL_END
