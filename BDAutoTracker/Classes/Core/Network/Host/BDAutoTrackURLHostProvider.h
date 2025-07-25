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

@interface BDAutoTrackURLHostProvider : NSObject

+ (instancetype)sharedInstance;

- (NSString *)URLForURLType:(BDAutoTrackRequestURLType)type
                      appID:(NSString *)appID;

- (BOOL)registerHostItem:(id<BDAutoTrackURLHostItemProtocol>)hostItem;

@end

NS_ASSUME_NONNULL_END
