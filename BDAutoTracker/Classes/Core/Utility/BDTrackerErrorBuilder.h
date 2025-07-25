//
//  BDTrackerErrorBuilder.h
//  RangersAppLog
//
//  Created by bytedance on 9/26/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerErrorBuilder : NSObject

+ (instancetype)builder;

- (instancetype)withDomain:(NSErrorDomain)code;

- (instancetype)withCode:(NSUInteger)code;

- (instancetype)withDescription:(nullable NSString *)description;

- (instancetype)withDescriptionFormat:(NSString *)format, ...;

- (instancetype)withFailureReason:(nullable NSString *)reason;

- (instancetype)withUnderlyingError:(nullable NSError *)error;

- (NSError *)build;

- (BOOL)buildError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
