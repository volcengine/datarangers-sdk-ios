//
//  BDAutoTrackClientABTestProtocol.h
//  Pods
//
//  Created by bytedance on 2023/10/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack;

typedef void (^ExposeBlock)(NSString *exposedVid, NSArray * excludeVids);

@interface BDAutoTrackClientABTestProtocol : NSObject

- (instancetype)initWithAppID:(NSString *)appID;

- (nullable id)getConfig:(NSString *)key;

- (void)exposeBlock:(ExposeBlock)block;

- (NSArray *)exposedVids;

- (void)clearExposeBlock:(dispatch_block_t)block;

- (void)fetchLocalShuntVersionInfo;


@end

NS_ASSUME_NONNULL_END
