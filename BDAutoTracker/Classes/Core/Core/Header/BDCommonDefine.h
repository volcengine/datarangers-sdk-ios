//
//  BDCommonDefine.h
//  RangersAppLog
//
//  Created by bob on 2020/3/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonEnumDefine.h"

#define APPLOG_API_AVALIABLE(x)
#define APPLOG_API_DEPRECATED __deprecated
#define APPLOG_API_DEPRECATED_WITH_REPLACEMENT(msg) __deprecated_msg("please use '" msg "'")
#define APPLOG_STATIC_ASSERT(COND,MSG) typedef char static_assertion_##MSG[(COND)?1:-1]

#ifndef BDCommonDefine_h
#define BDCommonDefine_h

NS_ASSUME_NONNULL_BEGIN


@protocol BDAutoTrackable <NSObject>

@required
- (NSDictionary *)bdAutoTrackParameters;

@end

typedef void(^BDAutoTrackLogger)(NSString * _Nullable log);

typedef NSString * _Nullable (^BDAutoTrackRequestURLBlock)(BDAutoTrackServiceVendor vendor, BDAutoTrackRequestURLType requestURLType);

typedef NSString * _Nullable (^BDAutoTrackRequestHostBlock)(BDAutoTrackServiceVendor vendor, BDAutoTrackRequestURLType requestURLType);

typedef NSDictionary * _Nullable (^BDAutoTrackCommonParamtersBlock)(BDAutoTrackServiceVendor vendor, BDAutoTrackRequestURLType requestURLType, NSDictionary *commonParamters);

typedef NSDictionary<NSString*, id> *_Nonnull (^BDAutoTrackCustomHeaderBlock)(void);

typedef NSString * _Nonnull (^BDAutoTrackMockBlock)(void);

typedef BDAutoTrackEventPolicy (^BDAutoTrackEventHandler)(BDAutoTrackDataType type, NSString *event, NSMutableDictionary<NSString *, id> *properties, NSDictionary<NSString *, id> *basicData);

@protocol BDAutoTrackSchemeHandler <NSObject>


- (BOOL)handleURL:(NSURL *)URL appID:(NSString *)appID scene:(nullable id)scene;

@end

NS_ASSUME_NONNULL_END
#endif 
