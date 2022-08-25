//
//  RangersAppLogConfig.m
//  RangersAppLog
//
//  Created by bob on 2020/5/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersAppLogConfig.h"

@interface RangersAppLogConfig ()

@end

@implementation RangersAppLogConfig

+ (instancetype)sharedInstance {
    static RangersAppLogConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
        [sharedInstance setSeversidePickerAvailable: NO];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.defaultVendor = nil;
    }
    
    return self;
}

@end
