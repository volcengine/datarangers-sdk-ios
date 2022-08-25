//
//  BDAutoTrackServiceCenter.m
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackService.h"
#import "RangersLog.h"

@interface BDAutoTrackServiceCenter ()

/// appid {serviceName:service}
@property (nonatomic, strong) NSMutableDictionary<NSString * ,NSMutableDictionary<NSString *, id<BDAutoTrackService>> *> *services;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDAutoTrackServiceCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.services = [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

+ (instancetype)defaultCenter {
    static BDAutoTrackServiceCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)registerService:(id<BDAutoTrackService>)service {
    if (service.appID.length < 1 || service.serviceName.length < 1) {
        return;
    }

    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    NSMutableDictionary<NSString *, id<BDAutoTrackService>> *appServices = [self.services objectForKey:service.appID];
    if (![appServices isKindOfClass:[NSMutableDictionary class]]) {
        appServices = [NSMutableDictionary new];
        [self.services setValue:appServices forKey:service.appID];
    }
    [appServices setValue:service forKey:service.serviceName];
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (void)unregisterService:(id<BDAutoTrackService>)service {
    if (service.appID.length < 1 || service.serviceName.length < 1) {
        return;
    }
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    NSMutableDictionary<NSString *, id<BDAutoTrackService>> *appServices = [self.services objectForKey:service.appID];
    if ([appServices isKindOfClass:[NSMutableDictionary class]]) {
        [appServices removeObjectForKey:service.serviceName];
    }
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (id<BDAutoTrackService>)serviceForName:(NSString *)serviceName appID:(NSString *)appID {
    if (appID.length < 1 || serviceName.length < 1) {
        return nil;
    }
    id<BDAutoTrackService> service = nil;
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    NSMutableDictionary<NSString *, id<BDAutoTrackService>> *appServices = [self.services objectForKey:appID];
    if ([appServices isKindOfClass:[NSMutableDictionary class]]) {
        service = [appServices objectForKey:serviceName];
    }
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
    
    return service;
}

- (NSArray<id<BDAutoTrackService>> *)servicesForName:(NSString *)serviceName {
    if (serviceName.length < 1) {
        return nil;
    }
    NSMutableArray<id<BDAutoTrackService>> *services = [NSMutableArray new];
    id<BDAutoTrackService> service = nil;
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    for (NSMutableDictionary<NSString *,id<BDAutoTrackService>> *appServices in self.services.allValues) {
        service = [appServices objectForKey:serviceName];
        if (service) {
            [services addObject:service];
        }
    }
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }

    return services;
}

- (void)unregisterAllServices {
    intptr_t timeout = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    self.services = [NSMutableDictionary new];
    if (!timeout) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

@end

id<BDAutoTrackService> bd_standardServices(NSString *serviceName, NSString *appID) {
    return [[BDAutoTrackServiceCenter defaultCenter] serviceForName:serviceName appID:appID];
}
