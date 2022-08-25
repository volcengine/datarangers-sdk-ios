//
//  NSURLRequest+RALDebug.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/8.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSURLRequest+RALDebug.h"

#ifdef DEBUG

@implementation NSURLRequest (RALDebug)
/* 生成VSCode「REST Client」插件所需要的请求格式（HTTP 语言） */
- (NSString *)debug_VSCodeRESTClientPlugin_HTTP {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:[NSString stringWithFormat:@"%@ %@ %@\n", self.HTTPMethod, self.URL.absoluteString, @"HTTP/1.1"]];
    
    NSDictionary *fields = self.allHTTPHeaderFields;
    for (NSString *headerName in fields) {
        NSString *headerVal = fields[headerName];
        [result appendString:[NSString stringWithFormat:@"%@: %@\n", headerName, headerVal]];
    }
        
    NSString *body = [[NSString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
    [result appendString:[NSString stringWithFormat:@"\n%@\n\n###", body]];
    
    return result;
}

/* 生成VSCode「REST Client」插件所需要的请求格式（cURL 格式） */
- (NSString *)debug_VSCodeRESTClientPlugin_cURL {
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:[NSString stringWithFormat:@"curl -i -X %@ ", self.HTTPMethod]];
    [result appendString:[NSString stringWithFormat:@"\"%@\" ", self.URL.absoluteString]];
    
    NSDictionary *fields = self.allHTTPHeaderFields;
    for (NSString *headerName in fields) {
        NSString *headerVal = fields[headerName];
        [result appendString:[NSString stringWithFormat:@"-H \"%@: %@\" ", headerName, headerVal]];
    }
        
    NSString *body = [[NSString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
    [result appendString:[NSString stringWithFormat:@"-d \"%@\"", body]];
    
    return result;
}
@end

#endif
