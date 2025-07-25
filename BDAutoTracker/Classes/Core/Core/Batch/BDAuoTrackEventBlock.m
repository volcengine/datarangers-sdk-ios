//
//  BDAuoTrackEventBlock.m
//  RangersAppLog
//
//  Created by bytedance on 2022/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDefaults.h"
#import "BDAuoTrackEventBlock.h"

static NSString * const kBDAutoTrackEventBlockListKey          = @"block_list";
static NSString * const kBDAutoTrackEventWhiteListKey          = @"white_list";

@interface BDAuoTrackEventBlock()

@property (nonatomic, strong) NSMutableSet *blockSet;
@property (nonatomic, strong) NSMutableSet *whiteSet;
@property (nonatomic, strong) BDAutoTrackDefaults *defaults;

@end

@implementation BDAuoTrackEventBlock

- (instancetype)initWithAppID:(NSString *)appID {
    if (self) {
        self.appID = appID;
        self.defaults = [BDAutoTrackDefaults defaultsWithAppID:appID];
        self.blockSet = [self createBlockSet];
        self.whiteSet = [self createWhiteSet];
    }
    return self;
}

- (NSMutableSet *)createBlockSet {
    NSMutableSet *blockSet = [NSMutableSet new];
    NSArray *blockList = [self.defaults arrayValueForKey:kBDAutoTrackEventBlockListKey];
    if (blockList) {
        [blockSet addObjectsFromArray:blockList];
    }
    return blockSet;
}

- (NSMutableSet *)createWhiteSet {
    NSMutableSet *whiteSet = [NSMutableSet new];
    NSArray *whiteList = [self.defaults arrayValueForKey:kBDAutoTrackEventWhiteListKey];
    if (whiteList) {
        [whiteSet addObjectsFromArray:whiteList];
    }
    return whiteSet;
}

- (void)updateBlockList:(NSArray *)blockList {
    @synchronized (self) {
        [self.blockSet removeAllObjects];
        [self.blockSet addObjectsFromArray:blockList];
        [self.defaults setValue:self.blockSet.allObjects forKey:kBDAutoTrackEventBlockListKey];
    }
}

- (void)updateWhiteList:(NSArray *)whiteList {
    @synchronized (self) {
        [self.whiteSet removeAllObjects];
        [self.whiteSet addObjectsFromArray:whiteList];
        [self.defaults setValue:self.whiteSet.allObjects forKey:kBDAutoTrackEventWhiteListKey];
    }
}

- (BOOL)hasEvent:(NSString *)event {
    @synchronized (self) {
        if (self.blockSet && self.blockSet.count > 0) {
            if ([self.blockSet containsObject:event]) {
                return YES;
            }
        }
        
        if (self.whiteSet && self.whiteSet.count > 0) {
            if (![self.whiteSet containsObject:event]) {
                return YES;
            }
        }
        
        return NO;
    }
}

@end
