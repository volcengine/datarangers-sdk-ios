//
//  NSURL+ral_ALink.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/7/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (ral_ALink)

- (nullable NSString *)ral_alink_token;

- (nullable NSArray <NSURLQueryItem *> *)ral_alink_custom_params;

@end

NS_ASSUME_NONNULL_END
