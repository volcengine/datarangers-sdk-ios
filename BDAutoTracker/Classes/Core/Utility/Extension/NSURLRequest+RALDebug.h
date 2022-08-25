//
//  NSURLRequest+RALDebug.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/8.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG

@interface NSURLRequest (RALDebug)

- (NSString *)debug_VSCodeRESTClientPlugin_HTTP;

- (NSString *)debug_VSCodeRESTClientPlugin_cURL;

@end

#endif

NS_ASSUME_NONNULL_END
