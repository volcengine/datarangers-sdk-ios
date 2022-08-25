//
//  BDAutoTrackDefaults_Fallback.m
//  Aspects
//
//  Created by bob on 2019/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackDefaults_Fallback.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMacro.h"



@interface BDAutoTrackDefaults_Fallback ()

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *plistPath;
@property (nonatomic, strong) NSMutableDictionary *rawData;  // guarded by lock
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDAutoTrackDefaults_Fallback

- (instancetype)initWithAppID:(NSString *)appID name:(NSString *)name {
    self = [super init];
    if (self) {
        self.appID = appID;
        NSString *plistPath = bd_trackerLibraryPathForAppID(appID);
        plistPath = [plistPath stringByAppendingPathComponent:name];
        self.plistPath = plistPath;
        self.rawData = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath] ?: [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

#pragma mark - get
- (NSObject *)objectForKey:(NSString *)key {
    BDSemaphoreLock(self.semaphore);
    NSObject *object = [self.rawData objectForKey:key];
    BDSemaphoreUnlock(self.semaphore);
    return object;
}


#pragma mark - set
- (void)removeObjectForKey:(NSString *)key {
    [self setValue:nil forKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (key) {
        BDSemaphoreLock(self.semaphore);
        [self.rawData setValue:value forKey:key];
        BDSemaphoreUnlock(self.semaphore);
    }
}

#pragma mark save
- (void)saveDataToFile {
    BDSemaphoreLock(self.semaphore);
    //    NSDictionary *data = bd_trueDeepCopyOfDictionary(self.rawData);
    // Since self.rawData is guarded by lock, it is OK to write it directly(or just make a shadow copy).
    NSDictionary *data = [self.rawData copy];
    if (@available(iOS 11, *)) {
        NSError *err;
        [data writeToURL:[NSURL fileURLWithPath:self.plistPath] error:&err];
#ifdef DEBUG
        NSLog(@"[yq-debug]Defaults saveDataToFile Error: %@", err);
#endif
    } else {
        [data writeToFile:self.plistPath atomically:YES];
    }
    BDSemaphoreUnlock(self.semaphore);
}

- (void)clearAllData {
    BDSemaphoreLock(self.semaphore);
    self.rawData = [NSMutableDictionary new];
    [[NSFileManager defaultManager] removeItemAtPath:self.plistPath error:nil];
    BDSemaphoreUnlock(self.semaphore);
}


@end
