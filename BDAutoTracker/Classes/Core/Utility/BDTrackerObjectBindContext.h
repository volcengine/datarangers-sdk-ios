//
//  BDTrackerObjectBindContext.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/31.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack;
@interface BDAutoTrackerBindingContext : NSObject
@end



@interface NSObject (BDAutoTrackBinding)

- (BDAutoTrackerBindingContext *)bdtracker_context;

- (NSString *)bdtracker_pointerId;

@end




NS_ASSUME_NONNULL_END
