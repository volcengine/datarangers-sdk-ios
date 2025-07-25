//
//  BDAutoTrack+Profile.m
//  Applog
//
//  Created by 朱元清 on 2020/9/11.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Private.h"
#import "BDAutoTrack+Profile.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackDataCenter.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackProfileReporter.h"
#import "BDAutoTrackEventCheck.h"
#import <objc/runtime.h>

static const NSTimeInterval profileExpireTimeRange = 60.0;
static void *setFlowControlAK = &setFlowControlAK;
static void *setOnceFlowControlAK = &setOnceFlowControlAK;

typedef enum : NSUInteger {
    BDProfileRequestTypeSet,
    BDProfileRequestTypeSetOnce,
    BDProfileRequestTypeUnset,
    BDProfileRequestTypeIncrement,
    BDProfileRequestTypeAppend
} BDProfileRequestType;

@interface BDProfileEntry : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *valueHash;
@property (nonatomic) NSTimeInterval timeSince1970;

@end

@implementation BDProfileEntry

- (instancetype)initWithProfileName:(NSString*)profileName value:(NSObject *)value {
    self = [super init];
    if (self) {
        self.name = profileName;
        self.valueHash = [self.class calcValueHash:value];
        self.timeSince1970 = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (BOOL)remainsValid {
    if ([[NSDate date] timeIntervalSince1970] - self.timeSince1970 < profileExpireTimeRange) {
        return YES;  // if is within the time range, then is valid
    }
    
    return NO;
}

- (BOOL)hasSameValueWithValue:(NSObject *)value {
    return [self.valueHash isEqualToString:[self.class calcValueHash:value]];
}

+ (NSString *)calcValueHash:(NSObject *)value {
    NSMutableString *content = [NSMutableString new];
    NSString *mangledValue;
    NSString *resultHash;
    
    if ([value isKindOfClass:NSString.class]) {
        content = [(NSString *)value mutableCopy];
        mangledValue = [NSString stringWithFormat:@"%@%@", NSStringFromClass(value.class), content];
        resultHash = mangledValue;
    } else if ([value isKindOfClass:NSNumber.class]) {
        content = [[(NSNumber *)value stringValue] mutableCopy];
        mangledValue = [NSString stringWithFormat:@"%@%@", NSStringFromClass(value.class), content];
        resultHash = mangledValue.length < 1000 ? mangledValue : bd_calc_md5([mangledValue cStringUsingEncoding:NSUTF8StringEncoding]);
    } else if ([value isKindOfClass:NSArray.class]) {
        NSArray *sortedArray = [(NSArray *)value sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }];
        [content appendString: [NSString stringWithFormat:@"%3lu", (unsigned long)[(NSArray *)value count]]];
        [content appendString: [sortedArray componentsJoinedByString:@","]];
        mangledValue = [NSString stringWithFormat:@"%@%@", NSStringFromClass(value.class), content];
        resultHash = bd_calc_md5([mangledValue cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    return resultHash;
}
@end

@interface BDAutoTrack (Profile)
@property (nonatomic, strong) BDAutoTrackProfileReporter *profileReporter;
@end

@implementation BDAutoTrack (Profile)

#pragma mark public

- (void)profileSet:(NSDictionary *)profileDict {
    if (self.showDebugLog) {
        bd_checkProfileDictionary(self, profileDict);
    }
    [self impl_profileSet:profileDict];
}

- (void)profileSetOnce:(NSDictionary *)profileDict {
    if (self.showDebugLog) {
        bd_checkProfileDictionary(self, profileDict);
    }
    [self impl_profileSetOnce:profileDict];
}

- (void)profileUnset:(NSString *)profileName {
    if (self.showDebugLog) {
        bd_checkProfileName(self, profileName);
    }
    [self impl_profileUnset:profileName];
}

- (void)profileIncrement:(NSDictionary *)profileDict {
    if (self.showDebugLog) {
        bd_checkProfileDictionary(self, profileDict);
    }
    [self impl_profileIncrement:profileDict];
}

- (void)profileAppend:(NSDictionary *)profileDict {
    if (self.showDebugLog) {
        bd_checkProfileDictionary(self, profileDict);
    }
    [self impl_profileAppend:profileDict];
}

+ (void)profileSet:(NSDictionary *)profileDict {
    [[BDAutoTrack sharedTrack] profileSet:profileDict];
}

+ (void)profileSetOnce:(NSDictionary *)profileDict {
    [[BDAutoTrack sharedTrack] profileSetOnce:profileDict];
}

+ (void)profileUnset:(NSString *)profileName {
    [[BDAutoTrack sharedTrack] profileUnset:profileName];
}

+ (void)profileIncrement:(NSDictionary *)profileDict {
    [[BDAutoTrack sharedTrack] profileIncrement:profileDict];
}

+ (void)profileAppend:(NSDictionary *)profileDict {
    [[BDAutoTrack sharedTrack] profileAppend:profileDict];
}

#pragma mark private
#pragma mark profile事件上报
- (BOOL)profileEvent:(NSString *)event params:(NSDictionary *)params {
    NSDictionary *trackData = @{kBDAutoTrackEventType:[event mutableCopy],
                                kBDAutoTrackEventData:[params copy]};
    
    if (self.config.rollback) {
        [self.dataCenter trackProfileEventWithData:trackData];
    } else {
        [self.eventGenerator trackEventType:BDAutoTrackTableProfile eventBody:trackData options:nil];
    }
   
    
    return YES;
}

- (NSMutableDictionary *)validateProfileDict:(NSDictionary *)profileDict {
    profileDict = [profileDict copy];
    NSMutableDictionary *validatedProfileDict = [NSMutableDictionary new];
    
    for (NSString *key in profileDict) {
        NSObject *value = profileDict[key];
        if ([key isKindOfClass:NSString.class]) {
            BOOL isValidValue = NO;
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                isValidValue = YES;
            } else if ([value isKindOfClass:NSArray.class]) {
                isValidValue = YES;
                for (NSObject *e in (NSArray *)value) {
                    if (![e isKindOfClass:NSString.class]) {
                        isValidValue = NO;  // 存在元素不是字符串，不合法
                    }
                }
            }
            
            if (isValidValue) {
                [validatedProfileDict setObject:value forKey:key];
            }
        }
    }
    
    return validatedProfileDict;
}

- (BOOL)reportProfileDict:(NSDictionary *)profileDict reqType:(BDProfileRequestType)type {
    NSString *eventV3Name;
    NSDictionary *params = profileDict;;
    switch (type) {
        case BDProfileRequestTypeSet:
            eventV3Name = @"__profile_set";
            break;
        case BDProfileRequestTypeSetOnce:
            eventV3Name = @"__profile_set_once";
            break;
        case BDProfileRequestTypeUnset:
            eventV3Name = @"__profile_unset";
            break;
        case BDProfileRequestTypeIncrement:
            eventV3Name = @"__profile_increment";
            break;
        case BDProfileRequestTypeAppend:
            eventV3Name = @"__profile_append";
            break;
        default:
            break;
    }
    if (eventV3Name && params) {
        BOOL ret = [self profileEvent:eventV3Name params:params];
        return ret;
    }
    return NO;
}

#pragma mark - impl

- (BOOL)impl_profileSet:(NSDictionary *)profileDict {
    NSString *ssid = bd_registerSSID(self.appID);
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    NSArray *snapshotKeys = validatedProfileDict.allKeys;
    NSMutableArray *dupValueKeys = [NSMutableArray array];
    
    for (NSString *name in snapshotKeys) {
        NSObject *value = validatedProfileDict[name];
        BDProfileEntry *profileEntry = [[self profileEntriesForSSID:ssid] objectForKey:name];
        if (profileEntry
            && [profileEntry.name isEqualToString:name] &&
            [profileEntry.valueHash isEqualToString:[BDProfileEntry calcValueHash:value]]) {
            [dupValueKeys addObject:name];
            continue;
        }
        profileEntry = [[BDProfileEntry alloc] initWithProfileName:name value:value];
        [[self profileEntriesForSSID:ssid] setObject:profileEntry forKey:name];
    }

    if (dupValueKeys.count == validatedProfileDict.allKeys.count) {
        return NO;
    }
    
    [validatedProfileDict removeObjectsForKeys:dupValueKeys];
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeSet];
    }
    return NO;
}

- (BOOL)impl_profileSetOnce:(NSDictionary *)profileDict {
    NSString *ssid = bd_registerSSID(self.appID);
    
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    for (NSString *key in validatedProfileDict.allKeys) {
        if ([[self profileNamesForSSID:ssid] containsObject:key]) {
            [validatedProfileDict removeObjectForKey:key];
        } else {
            [[self profileNamesForSSID:ssid] addObject:key];
        }
    }
    
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeSetOnce];
    }
    return NO;
}

- (BOOL)impl_profileUnset:(NSString *)profileName {
    NSString *ssid = bd_registerSSID(self.appID);
    BOOL ret = [self reportProfileDict:@{profileName: @(1)} reqType:BDProfileRequestTypeUnset];
    if (ret) {
        if ([[self profileNamesForSSID:ssid] containsObject:profileName]) {
            [[self profileNamesForSSID:ssid] removeObject:profileName];
        }
        if ([[self profileEntriesForSSID:ssid] objectForKey:profileName]) {
            [[self profileEntriesForSSID:ssid] removeObjectForKey:profileName];
        }
    }
    return ret;
}

- (BOOL)impl_profileIncrement:(NSDictionary <NSString *, NSNumber *> *)profileDict {
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    for (NSString *key in validatedProfileDict.allKeys) {
        NSObject *value = validatedProfileDict[key];
        if (![value isKindOfClass:NSNumber.class] || [[(NSNumber *)value stringValue] containsString:@"."]) {
            [validatedProfileDict removeObjectForKey:key];
        }
    }
    
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeIncrement];
    }
    return NO;
}

- (BOOL)impl_profileAppend:(NSDictionary *)profileDict {
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    for (NSString *key in validatedProfileDict.allKeys) {
        NSObject *value = validatedProfileDict[key];
        
        if (![value isKindOfClass:NSArray.class] && ![value isKindOfClass:NSString.class]) {
            [validatedProfileDict removeObjectForKey:key];
        }
        else if ([value isKindOfClass:NSString.class]) {
            [validatedProfileDict setObject:@[value] forKey:key];
        }
    }
    
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeAppend];
    }
    return NO;
}

#ifdef DEBUG
- (void)_resetProfileFlowControlPolicy {
    [self setControledProfileEntries:nil];
    [self setControledProfileNames:nil];
}
#endif

#pragma mark 关联对象
- (NSMutableDictionary <NSString *, NSMutableDictionary *> *)controledProfileEntries {
    if (!objc_getAssociatedObject(self, setFlowControlAK)) {
        [self setControledProfileEntries:[NSMutableDictionary new]];
    }
    return objc_getAssociatedObject(self, setFlowControlAK);
}

- (void)setControledProfileEntries:(NSMutableDictionary <NSString *, NSMutableDictionary *> *)profileEntries {
    objc_setAssociatedObject(self, setFlowControlAK, profileEntries, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary <NSString *, NSMutableSet *> *)controledProfileNames {
    if (!objc_getAssociatedObject(self, setOnceFlowControlAK)) {
        [self setControledProfileNames:[NSMutableDictionary new]];
    }
    return objc_getAssociatedObject(self, setOnceFlowControlAK);
}

- (void)setControledProfileNames:(NSMutableDictionary <NSString *, NSMutableSet *> *)profileNames {
    objc_setAssociatedObject(self, setOnceFlowControlAK, profileNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BDAutoTrackProfileReporter *)profileReporter {
    if (!objc_getAssociatedObject(self, @selector(profileReporter))) {
        BDAutoTrackProfileReporter *profileReporter = [[BDAutoTrackProfileReporter alloc] initWithAppID:self.appID associatedTrack:self];
        [self setProfileReporter:profileReporter];
    }
    return objc_getAssociatedObject(self, @selector(profileReporter));
}

- (void)setProfileReporter:(BDAutoTrackProfileReporter *)profileReporter {
    objc_setAssociatedObject(self, @selector(profileReporter), profileReporter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark -
- (NSMutableDictionary *)profileEntriesForSSID:(NSString *)ssid {
    if (!ssid) {
        return nil;
    }
    NSMutableDictionary <NSString *, NSMutableDictionary *> *controledProfileEntries = [self controledProfileEntries];
    if (![controledProfileEntries objectForKey:ssid]) {
        [controledProfileEntries setObject:[NSMutableDictionary new] forKey:ssid];
    }
    
    return [controledProfileEntries objectForKey:ssid];
}

- (NSMutableSet *)profileNamesForSSID:(NSString *)ssid {
    if (!ssid) {
        return nil;
    }
    NSMutableDictionary <NSString *, NSMutableSet *> *controledProfileNames = [self controledProfileNames];
    if (![controledProfileNames objectForKey:ssid]) {
        [controledProfileNames setObject:[NSMutableSet new] forKey:ssid];
    }
    
    return [controledProfileNames objectForKey:ssid];
}

@end
