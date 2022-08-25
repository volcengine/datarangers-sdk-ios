//
//  BDKeyWindowTracker.m
//  RangersAppLog
//
//  Created by bob on 2019/8/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDKeyWindowTracker.h"

NSString * const BDDefaultScene  = @"Default Configuration";

@interface BDKeyWindowTracker ()

@property (nonatomic, strong) NSMapTable *keyWindows;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDKeyWindowTracker

+ (instancetype)sharedInstance {
    static BDKeyWindowTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keyWindows = [NSMapTable strongToWeakObjectsMapTable];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

- (void)trackScene:(NSString *)name keyWindow:(UIWindow *)keyWindow {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (!keyWindow) {
        [self.keyWindows removeObjectForKey:name];
    } else {
        [self.keyWindows setObject:keyWindow forKey:name];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (UIWindow *)keyWindowForScene:(NSString *)name {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    UIWindow *value = [self.keyWindows objectForKey:name];
    dispatch_semaphore_signal(self.semaphore);

    return value;
}

- (void)removeKeyWindowForScene:(NSString *)name {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.keyWindows removeObjectForKey:name];
    dispatch_semaphore_signal(self.semaphore);
}

- (UIWindow *)keyWindow {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    UIWindow *value = [self.keyWindows objectForKey:BDDefaultScene];
    if (!value) {
        value = [UIApplication sharedApplication].keyWindow;
    }
    dispatch_semaphore_signal(self.semaphore);

    return value;
}

- (void)setKeyWindow:(UIWindow *)keyWindow {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (!keyWindow) {
        [self.keyWindows removeObjectForKey:BDDefaultScene];
    } else {
        [self.keyWindows setObject:keyWindow forKey:BDDefaultScene];
    }
    dispatch_semaphore_signal(self.semaphore);
}

@end
