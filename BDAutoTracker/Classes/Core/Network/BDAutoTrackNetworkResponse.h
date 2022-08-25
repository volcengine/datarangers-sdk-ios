//
//  BDAutoTrackNetworkResponse.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/10/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 表示一个服务器响应。目前支持JSON格式的响应。
@interface BDAutoTrackNetworkResponse : NSObject

/// HTTP status code
@property (nonatomic) NSInteger statusCode;

@property (nonatomic) BOOL isDictionaryResponse;
/// 返回字典类型响应数据。如果不是字典类型，则返回nil。
@property (strong, nonatomic, nullable) NSDictionary *dictionaryResponse;

@property (nonatomic) BOOL isArrayResponse;
/// 返回数组类型响应数据。如果不是数组类型，则返回nil。
@property (strong, nonatomic, nullable) NSArray *arrayResponse;

//@property (nonatomic, nullable) NSError *responseError;

- (BOOL)isValidResponse;

- (instancetype)initWithStatusCode:(NSInteger)statusCode responseData:(NSData *)responseData;

@end

NS_ASSUME_NONNULL_END
