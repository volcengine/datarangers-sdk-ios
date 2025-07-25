//
//  BDAuoTrackEventBlock.h
//  RangersAppLog
//
//  Created by bytedance on 2022/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

@interface BDAuoTrackEventBlock : NSObject

@property (nonatomic, copy) NSString *appID;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)updateBlockList:(NSArray *)blockList;

- (void)updateWhiteList:(NSArray *)whiteList;

- (BOOL)hasEvent:(NSString *)event;

@end
