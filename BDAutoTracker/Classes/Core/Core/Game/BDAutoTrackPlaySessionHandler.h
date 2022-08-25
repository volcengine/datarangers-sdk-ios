//
//  BDAutoTrackPlaySessionHandler.h
//  Applog
//
//  Created by bob on 2019/4/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackPlaySessionHandler : NSObject

/// default 60 s
@property (nonatomic, assign) CFTimeInterval playSessionInterval;

- (void)startPlaySessionWithTime:(NSString *)startTime;

- (void)stopPlaySession;

@end

NS_ASSUME_NONNULL_END
