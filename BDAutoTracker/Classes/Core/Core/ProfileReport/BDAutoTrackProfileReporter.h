//
//  BDAutoTrackProfileReporter.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/3/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

@class BDAutoTrack;

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackProfileReporter : NSObject

@property (nonatomic, readonly) NSString *appID;

- (instancetype)initWithAppID:(NSString *)appID associatedTrack:(BDAutoTrack *)track;

- (void)sendProfileTrack;

@end

NS_ASSUME_NONNULL_END
