//
//  BDAutoTrackerALinkPasteBoardParser.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/8/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const s_pb_DemandPrefix = @"datatracer:";

@interface BDAutoTrackerALinkPasteBoardParser : NSObject

@property (nonatomic, readonly) NSString *allQueryString;

- (instancetype)initWithPasteBoardItem:(NSString *)pbItem;

- (NSString* )ab_version;

- (NSString* )tr_web_ssid;


@end

NS_ASSUME_NONNULL_END
