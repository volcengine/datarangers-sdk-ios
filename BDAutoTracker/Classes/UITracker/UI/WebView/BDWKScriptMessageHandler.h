//
//  BDWKScriptMessageHandler.h
//  Applog
//
//  Created by bob on 2019/4/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDWKScriptMessageHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, copy, readonly) NSString *messageName;
@property (nonatomic, copy, readonly)  void (^handler)(WKScriptMessage *message);

+ (instancetype)handlerWithMessageName:(NSString *)messageName handler:(void (^)(WKScriptMessage *message))handler;

@end

NS_ASSUME_NONNULL_END
