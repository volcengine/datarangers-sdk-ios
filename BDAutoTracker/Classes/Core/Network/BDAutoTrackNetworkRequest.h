//
//  BDAutoTrackNetworkRequest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/13.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackNetworkManager.h"
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// extern for Unit Test
FOUNDATION_EXTERN NSMutableDictionary * bd_requestURLParameters(NSString *appID);
FOUNDATION_EXTERN NSString * bd_validateRequestURL(NSString *requestURL);
FOUNDATION_EXTERN NSMutableDictionary * bd_requestPostHeaderParameters(NSString *appID);


NS_ASSUME_NONNULL_END
