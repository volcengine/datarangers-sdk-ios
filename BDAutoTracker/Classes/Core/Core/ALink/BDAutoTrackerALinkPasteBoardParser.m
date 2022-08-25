//
//  BDAutoTrackerALinkPasteBoardParser.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/8/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackerALinkPasteBoardParser.h"

@interface BDAutoTrackerALinkPasteBoardParser ()
@property (nonatomic, readwrite) NSString *allQueryString;

@property (nonatomic) NSString *contentURLString;
@property (nonatomic) NSURLComponents *contentComponents;

@end

@implementation BDAutoTrackerALinkPasteBoardParser

- (instancetype)initWithPasteBoardItem:(NSString *)pbItem {
    self = [super init];
    if (self) {
        if ([pbItem hasPrefix:s_pb_DemandPrefix]) {
            NSString *attrAsBase64String = [pbItem substringFromIndex:[s_pb_DemandPrefix length]];
            NSData *attrAsDecodedData = [[NSData alloc] initWithBase64EncodedString:attrAsBase64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
            NSString *query = [[NSString alloc] initWithData:attrAsDecodedData encoding:NSUTF8StringEncoding];
            self.allQueryString = query;
            self.contentURLString = [NSString stringWithFormat:@"%@//?%@", s_pb_DemandPrefix, query];
        }
        
    }
    return self;
}

- (NSString* )ab_version {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.contentURLString];
    NSString *result;
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"ab_version"]) {
            result = item.value;
        }
    }
    
    return result;
}

- (NSString* )tr_web_ssid {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.contentURLString];
    NSString *result;
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        if ([item.name isEqualToString:@"tr_web_ssid"]) {
            result = item.value;
        }
    }
    
    return result;
}

@end
