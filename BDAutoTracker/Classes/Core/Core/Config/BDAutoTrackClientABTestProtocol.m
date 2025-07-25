//
//  BDAutoTrackClientABTestProtocol.m
//  Pods
//
//  Created by bytedance on 2023/10/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackClientABTestProtocol.h"

@interface BDAutoTrackClientABTestProtocol ()

@property (nonatomic, copy) NSString *appID;

@end

@implementation BDAutoTrackClientABTestProtocol

- (instancetype)initWithAppID:(NSString *)appID
{
    self = [super init];
    if (self) {
        self.appID = appID;
        [self loadLocalShuntVersionInfo:appID];
    }
    return self;
}

- (nullable id)getConfig:(NSString *)key
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return nil;
    }
    
    SEL sel = NSSelectorFromString(@"getConfig:appID:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return nil;
    }
    
    id (*getConfig)(id, SEL, NSString *, NSString *) = (void *)imp;
    return getConfig(manager, sel, key, self.appID);
}

- (void)exposeBlock:(ExposeBlock)block
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return;
    }
    
    SEL sel = NSSelectorFromString(@"exposeBlock:appID:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return;
    }
    
    void (*exposeBlock)(id, SEL, ExposeBlock, NSString *) = (void *)imp;
    exposeBlock(manager, sel, block, self.appID);
}

- (NSArray *)exposedVids
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return @[];
    }
    
    SEL sel = NSSelectorFromString(@"exposedVids:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return @[];
    }
    
    NSArray* (*exposedVids)(id, SEL, NSString *) = (void *)imp;
    return exposedVids(manager, sel, self.appID);
}


- (id)clientABTestManager
{
    Class clz = NSClassFromString(@"BDAutoTrackClientABTestManager");
    if (!clz) {
        return nil;
    }
    
    SEL instanceSEL =   NSSelectorFromString(@"sharedInstance");
    IMP instanceIMP = [clz methodForSelector:instanceSEL];
    if (!instanceIMP) {
        return nil;
    }
    
    id (*sharedInstance)(id, SEL) = (void *)instanceIMP;
    return sharedInstance(clz, instanceSEL);
}

- (void)clearExposeBlock:(dispatch_block_t)block
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return;
    }
    
    SEL sel = NSSelectorFromString(@"clearExposeBlock:appID:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return;
    }
    
    void (*clearExposeBlock)(id, SEL, dispatch_block_t, NSString *) = (void *)imp;
    clearExposeBlock(manager, sel, block, self.appID);
}

- (void)fetchLocalShuntVersionInfo
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return;
    }
    SEL sel = NSSelectorFromString(@"fetchLocalShuntVersionInfo:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return;
    }
    void (*fetchLocalShuntVersionInfoIMPL)(id, SEL, NSString *) = (void *)imp;
    fetchLocalShuntVersionInfoIMPL(manager, sel, self.appID);
}

- (void)loadLocalShuntVersionInfo:(NSString *)appId
{
    id manager = [self clientABTestManager];
    if (!manager) {
        return;
    }
    SEL sel = NSSelectorFromString(@"loadLocalShuntVersionInfo:");
    IMP imp = [manager methodForSelector:sel];
    if (!imp) {
        return;
    }
    void (*fetchLocalShuntVersionInfoIMPL)(id, SEL, NSString *) = (void *)imp;
    fetchLocalShuntVersionInfoIMPL(manager, sel, self.appID);
}

@end
