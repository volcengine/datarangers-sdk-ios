//
//  BDWKScriptMessageHandler.m
//  Applog
//
//  Created by bob on 2019/4/16.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDWKScriptMessageHandler.h"

@interface BDWKScriptMessageHandler ()

@property (nonatomic, copy) NSString *messageName;
@property (nonatomic, copy)  void (^handler)(WKScriptMessage *message);

@end

@implementation BDWKScriptMessageHandler

+ (instancetype)handlerWithMessageName:(NSString *)messageName handler:(void (^)(WKScriptMessage *message))handler {
    BDWKScriptMessageHandler *messageHandler = [self new];
    messageHandler.messageName = messageName;
    messageHandler.handler = handler;

    return messageHandler;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:self.messageName]) {
        self.handler(message);
    }
}

@end
