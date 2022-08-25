//
//  NSURL+ral_ALink.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/7/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSURL+ral_ALink.h"

@implementation NSURL (ral_ALink)

- (BOOL)ral_alink_isUniversalLink {
    return [self.scheme isEqualToString:@"https"] || [self.scheme isEqualToString:@"http"];
}

- (NSString *)ral_alink_token {
    NSString *token;
    if ([self ral_alink_isUniversalLink]) {
        /* 处理 Universal Links */
        if ([self.pathComponents count] >= 3 &&
            [self.pathComponents[1] isEqualToString:@"a"]) {
            token = self.pathComponents[2];
        }
    }
    else {
        /* 处理 URL Scheme */
        NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
        NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
        for (NSURLQueryItem *queryItem in queryItems) {
            if ([queryItem.name isEqual:@"tr_token"]) {
                token = queryItem.value;
                break;
            }
        }
    }
    
    return token;
}

- (NSArray <NSURLQueryItem *> *)ral_alink_custom_params {
    /* Get ALink Custom Params */
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSPredicate *isCustomParamPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([evaluatedObject isKindOfClass:[NSURLQueryItem class]]) {
            NSURLQueryItem *item = (NSURLQueryItem *)evaluatedObject;
            return [item.name hasPrefix:@"tr_"] && ![item.name isEqualToString:@"tr_token"];
        }
        return NO;
    }];
    NSArray<NSURLQueryItem *> *queryItems = [components.queryItems filteredArrayUsingPredicate:isCustomParamPredicate];;
    return queryItems;
}

@end
