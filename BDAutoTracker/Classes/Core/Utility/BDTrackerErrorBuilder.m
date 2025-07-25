//
//  BDTrackerErrorBuilder.m
//  RangersAppLog
//
//  Created by bytedance on 9/26/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDTrackerErrorBuilder.h"

static NSString *const BDTrackerErrorDomain = @"BDTrackerErrorDomain";
NSErrorUserInfoKey const BDTrackerExtraUserInfoErrorKey = @"BDTrackerExtraUserInfoErrorKey";


@interface BDTrackerErrorBuilder ()

@property (nonatomic, assign)   NSInteger code;

@property (nonatomic, copy)     NSString *desc;

@property (nonatomic, strong)   NSError *underlyingError;

@property (nonatomic, copy)     NSString *reason;

@property (nonatomic, copy)     NSErrorDomain domain;

@property (nonatomic, strong)   NSDictionary *userInfo;

@end


@implementation BDTrackerErrorBuilder


+ (instancetype)builder
{
    return [BDTrackerErrorBuilder new];
}

- (instancetype)withCode:(NSUInteger)code;
{
    self.code = code;
    return self;
}

- (instancetype)withDescription:(NSString *)description
{
    self.desc = description;
    return self;
}

- (instancetype)withUserInfo:(NSDictionary *)userInfo
{
    self.userInfo = userInfo;
    return self;
}

- (instancetype)withDescriptionFormat:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    self.desc = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return self;
}

- (instancetype)withFailureReason:(NSString *)reason
{
    self.reason = reason;
    return self;
}

- (instancetype)withUnderlyingError:(nullable NSError *)error
{
    self.underlyingError = error;
    return self;
}

- (instancetype)withDomain:(NSErrorDomain)domain
{
    self.domain = domain;
    return self;
}

- (NSError *)build
{
    return
    [NSError errorWithDomain:[self userDomain]
                        code:[self userErrorCode]
                    userInfo:[self buildUserInfo]
     ];
}

- (BOOL)buildError:(NSError **)errorOut
{
    if (errorOut) {
        *errorOut = [self build];
    }
    return NO;
}


- (NSErrorDomain)userDomain
{
    
    if (!self.domain) {
        return BDTrackerErrorDomain;
    }
    return self.domain;
    
}

- (NSInteger)userErrorCode
{
    if (!self.code) {
        return 1;
    }
    return self.code;
}

- (NSDictionary *)buildUserInfo
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (self.desc) {
        userInfo[NSLocalizedDescriptionKey] = self.desc;
    }
    if (self.underlyingError) {
        userInfo[NSUnderlyingErrorKey] = self.underlyingError;
    }
    if (self.reason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = self.reason;
    }
    return userInfo.copy;
}


@end
