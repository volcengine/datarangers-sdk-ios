//
//  BDAutoTrackScriptMessageHandler.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/23.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 提供JS调用部分Native接口的能力
@interface BDAutoTrackScriptMessageHandler : NSObject <WKScriptMessageHandler>

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
