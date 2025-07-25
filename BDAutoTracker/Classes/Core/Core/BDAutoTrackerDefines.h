//
//  BDAutoTrackerDefines.h
//  RangersAppLog
//
//  Created by bytedance on 9/27/22.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    BDAutoTrackEventPriorityDefault = 0,        //batch
    BDAutoTrackEventPriorityRealtime = (99),    //realtime
} BDAutoTrackEventPriority;


NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackEventOption : NSObject

@property (nonatomic, copy) NSString *abtestingExperiments;

@end


NS_ASSUME_NONNULL_END
