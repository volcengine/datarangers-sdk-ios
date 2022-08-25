//
//  RangersRouter.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RangersRouting : NSObject

+ (instancetype)routing:(NSString *)service
                   base:(NSString *)appId
             parameters:(id)parameters;

@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *service;

@property (nonatomic) id parameters;

@end


@interface RangersRouter : NSObject

+ (id)sync:(RangersRouting *)routing;

@end

NS_ASSUME_NONNULL_END
