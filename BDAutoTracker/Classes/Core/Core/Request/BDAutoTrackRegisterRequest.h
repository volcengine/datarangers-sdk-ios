//
//  BDAutoTrackRegisterRequest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackRegisterRequest : BDAutoTrackRequest

@property (nonatomic, nullable) NSString *registeringUserUniqueID;

- (id)syncRegister:(NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
