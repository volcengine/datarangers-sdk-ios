//
//  BDAutoTrackIdentifier.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/10/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackIdentifier : NSObject

- (instancetype)initWithTracker:(id)tracker;

@property (nonatomic, assign) BOOL mockEnabled;

@property (nonatomic, copy) BDAutoTrackServiceVendor serviceVendor;

- (NSString *)vendorID;

- (NSString *)advertisingID;

- (void)clearIDs;

- (BOOL)isAuthorized;


@end

NS_ASSUME_NONNULL_END
