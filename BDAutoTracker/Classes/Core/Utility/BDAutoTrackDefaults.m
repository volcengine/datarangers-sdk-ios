//
//  BDAutoTrackDefaults.m
//  Aspects
//
//  Created by bob on 2019/8/19.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackDefaults.h"
#import "BDAutoTrackDefaults_Fallback.h"

#import "BDAutoTrackUtility.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"

@interface BDAutoTrackDefaults ()

@property (nonatomic, copy) NSString *appID;
@property (nonatomic) NSString *name;

@property (nonatomic) NSUserDefaults *realDefaults;
@property (nonatomic) NSString *suiteName;
@property (nonatomic) BDAutoTrackDefaults_Fallback *fallbackDefaults;  // lazy init

@property (nonatomic) BOOL shouldRestoreIsUserFirstLaunch;

@end

static NSString *defaultPlistFileName = @"config.plist";

@implementation BDAutoTrackDefaults

/// Instances created by this method will be cached in `allDefaults`.
+ (instancetype)defaultsWithAppID:(NSString *)appID {
    static NSMutableDictionary<NSString *, BDAutoTrackDefaults *> *allDefaults = nil;
    static dispatch_semaphore_t semaphore = NULL;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        allDefaults = [NSMutableDictionary new];
        semaphore = dispatch_semaphore_create(1);
    });

    if (![appID isKindOfClass:[NSString class]] || appID.length < 1) {
        return nil;
    }
    BDSemaphoreLock(semaphore);
    BDAutoTrackDefaults *defaults = [allDefaults objectForKey:appID];
    if (!defaults) {
        defaults = [[BDAutoTrackDefaults alloc] initWithAppID:appID];
        [allDefaults setValue:defaults forKey:appID];
    }
    BDSemaphoreUnlock(semaphore);

    return defaults;
}

- (instancetype)initWithAppID:(NSString *)appID {
    return [self initWithAppID:appID name:defaultPlistFileName];
}

/// dedicated initializer
/// @param appID Part of the suite name. Helps suite name unique within the app.
/// @param name Part of the suite name. Helps suite name unique within the app.
- (instancetype)initWithAppID:(NSString *)appID name:(NSString *)name {
    self = [super init];
    if (self) {
        self.suiteName = [NSString stringWithFormat:@"com.rangersapplog.%@.%@", appID, name];  // suite name should be unique within the app.
        self.realDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
        self.appID = appID;
        self.name = name;
        self.shouldRestoreIsUserFirstLaunch = YES;
    }

    return self;
}

// lazy init
- (BDAutoTrackDefaults_Fallback *)fallbackDefaults {
    if (!_fallbackDefaults) {
        _fallbackDefaults = [[BDAutoTrackDefaults_Fallback alloc] initWithAppID:self.appID name:self.name];
    }
    return _fallbackDefaults;
}

#pragma mark - get
- (BOOL)boolValueForKey:(NSString *)key {
    NSNumber *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        result = (NSNumber *)value;
    }
    
    return [result boolValue];
}

- (double)doubleValueForKey:(NSString *)key {
    NSNumber *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        result = (NSNumber *)value;
    }
    
    return [result doubleValue];
}

- (NSInteger)integerValueForKey:(NSString *)key {
    NSNumber *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        result = (NSNumber *)value;
    }
    
    return [result integerValue];
}

- (NSString *)stringValueForKey:(NSString *)key {
    NSString *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        result = (NSString *)value;
    }
    
    return result;
}

- (NSDictionary *)dictionaryValueForKey:(NSString *)key {
    NSDictionary *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        result = (NSDictionary *)value;
    }
    else if ([value isKindOfClass:[NSMapTable class]]) {
        NSMapTable *set = (NSMapTable *)value;
        result = set.dictionaryRepresentation;
    }
    
    return result;
}

- (NSArray *)arrayValueForKey:(NSString *)key {
    NSArray *result;
    
    NSObject *value = [self objectForKey:key];
    if ([value isKindOfClass:[NSArray class]]) {
        result = (NSArray *)value;
    }
    else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = (NSSet *)value;
        result = set.allObjects;
    }
    else if ([value isKindOfClass:[NSHashTable class]]) {
        NSHashTable *hashTable = (NSHashTable *)value;
        result = hashTable.allObjects;
    }
    
    return result;
}

- (NSObject *)objectForKey:(NSString *)key {
    [self _checkDataMigrationForKey:key];
    return [self.realDefaults objectForKey:key];
}

- (void)_checkDataMigrationForKey:(NSString *)key {
    if (![self.realDefaults objectForKey:key]) {
        NSObject *fallbackObject = [self.fallbackDefaults objectForKey:key];
        if (fallbackObject) {
            [self setValue:fallbackObject forKey:key];
        }
    }
}


#pragma mark - set
- (void)setDefaultValue:(id)value forKey:(NSString *)key {
    [self setValue:value forKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (value){
        [self.realDefaults setObject:value forKey:key];
    } else {
        [self.realDefaults removeObjectForKey:key];
    }
    
    [self _eraseMigratedDataForKey:key];
}

- (void)_eraseMigratedDataForKey:(NSString *)key {
    if ([self.fallbackDefaults objectForKey:key]) {
        [self.fallbackDefaults removeObjectForKey:key];
        [self.fallbackDefaults saveDataToFile];
    }
}

#pragma mark save
- (void)saveDataToFile {
    // No need to sync here according to the document of `- [NSUserDefaults synchronize]`.
    // So currently this method does nothing but satisfy old code calls.
}

#pragma mark clear data in cache and plist file
- (void)clearAllData {
    [self.realDefaults removePersistentDomainForName:self.suiteName];
    [self.fallbackDefaults clearAllData];
}

#pragma mark - is first launch
- (BOOL)isUserFirstLaunch {
    NSString *isFirstLaunchString = [self stringValueForKey:kBDAutoTrackIsFirstTimeLaunch];
    if (isFirstLaunchString == nil) {
        [self setValue:@"false" forKey:kBDAutoTrackIsFirstTimeLaunch];
        [self saveDataToFile];
        return YES;
    }
    
    return NO;
}

- (void)refreshIsUserFirstLaunch {
    self.shouldRestoreIsUserFirstLaunch = YES;
    if ([self stringValueForKey:kBDAutoTrackIsFirstTimeLaunch]) {
        [self setValue:nil forKey:kBDAutoTrackIsFirstTimeLaunch];
        [self saveDataToFile];
    }
}

- (BOOL)isAPPFirstLaunch {
    static BOOL s_isAPPFirstLaunch;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *key = [NSString stringWithFormat:@"%@-%@",kBDAutoTrackIsAPPFirstTimeLaunch,version];
        if ([self stringValueForKey:key] == nil) {
            s_isAPPFirstLaunch = YES;
            [self setValue:@"false" forKey:key];
            [self saveDataToFile];
        }
    });
    
    return s_isAPPFirstLaunch;
}

@end
