//
//  BDAutoTrackNetworkResponse.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/10/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackNetworkResponse.h"

@implementation BDAutoTrackNetworkResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _statusCode = 0;

        _isDictionaryResponse = NO;
        _dictionaryResponse = nil;

        _isArrayResponse = NO;
        _arrayResponse = nil;
        
//        _responseError = nil;
    }
    return self;
}

- (instancetype)initWithStatusCode:(NSInteger)statusCode responseData:(NSData *)responseData {
    self = [super init];
    if (self) {
        _statusCode = statusCode;
        if (responseData != nil) {
            // JSON反序列化
            NSError *JSONError = nil;
            id JSONObj = [NSJSONSerialization JSONObjectWithData:responseData
                                                        options:0
                                                          error:&JSONError];
            if (!JSONError) {
                if ([JSONObj isKindOfClass:[NSDictionary class]]) {
                    _isDictionaryResponse = YES;
                    _dictionaryResponse = JSONObj;
                } else if ([JSONObj isKindOfClass:[NSArray class]]) {
                    _isArrayResponse = YES;
                    _arrayResponse = JSONObj;
                }
            }
        }
    }
    return self;
}


- (BOOL)isValidResponse {
    return (_isDictionaryResponse && _dictionaryResponse) || (_isArrayResponse && _arrayResponse);
}


@end
