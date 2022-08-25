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
#import "BDAutoTrackDataCenter.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackProfileReporter.h"
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

/// 用于ProfileSet请求的流量控制
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

/// 在有效期内的profileEntry可能被限流（在用户、键、值三元素都相同的情况下）。在有效期外的不会被限流。
/// @return 当前ProfileEntry是否在有效期内
- (BOOL)remainsValid {
    if ([[NSDate date] timeIntervalSince1970] - self.timeSince1970 < profileExpireTimeRange) {
        return YES;  // if is within the time range, then is valid
    }
    
    return NO;
}

- (BOOL)hasSameValueWithValue:(NSObject *)value {
    return [self.valueHash isEqualToString:[self.class calcValueHash:value]];
}

/// 数组类型的值可能比较占内存。因此设计了valueHash.
/// @param value profile的值
/// @return 哈希后的profile值
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
    [self impl_profileSet:profileDict];
}

- (void)profileSetOnce:(NSDictionary *)profileDict {
    [self impl_profileSetOnce:profileDict];
}

- (void)profileUnset:(NSString *)profileName {
    [self impl_profileUnset:profileName];
}

- (void)profileIncrement:(NSDictionary *)profileDict {
    [self impl_profileIncrement:profileDict];
}

- (void)profileAppend:(NSDictionary *)profileDict {
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
    [self.dataCenter trackProfileEventWithData:trackData];
    
    return YES;
}

/// 对profileDict做类型检查。值类型不合法的KV对会被移除。
/// 类型合法的定义是字典的值的类型为 NSNumber | NSString | NSArray<NSString> 之一
/// @param profileDict 需要做类型检查的ProfileDict。
/// @return 类型合法的ProfileDict。
- (NSMutableDictionary *)validateProfileDict:(NSDictionary *)profileDict {
    profileDict = [profileDict copy];
    NSMutableDictionary *validatedProfileDict = [NSMutableDictionary new];
    
    for (NSString *key in profileDict) {
        NSObject *value = profileDict[key];
        if ([key isKindOfClass:NSString.class]) {
            // 判断value的类型是否合法
            BOOL isValidValue = NO;
            if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class]) {
                // 是数值和字符串类型，合法
                isValidValue = YES;
            } else if ([value isKindOfClass:NSArray.class]) {
                // 是数组类型，进一步判断是否元素都是字符串
                isValidValue = YES;
                for (NSObject *e in (NSArray *)value) {
                    if (![e isKindOfClass:NSString.class]) {
                        isValidValue = NO;  // 存在元素不是字符串，不合法
                    }
                }
            }
            
            // 如果合法，就添加
            if (isValidValue) {
                [validatedProfileDict setObject:value forKey:key];
            }
        } // End if key is NSString
    }  // End for
    
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
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self.profileReporter sendProfileTrack];  // 立刻返回，不耗时
//        });
        return ret;
    }
    return NO;
}

#pragma mark - impl
// impl。返回值表示是否进行了上报。设置该层是为了单元测试。

- (BOOL)impl_profileSet:(NSDictionary *)profileDict {
    
    NSString *ssid = [self ssID];
    // 通用类型检查
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    // 流量控制
    NSArray *snapshotKeys = validatedProfileDict.allKeys;
    for (NSString *name in snapshotKeys) {
        NSObject *value = validatedProfileDict[name];
        BDProfileEntry *profileEntry = [[self profileEntriesForSSID:ssid] objectForKey:name];
        // 若不存在或存在但已经过期，则重新添加
        if (!profileEntry || ![profileEntry remainsValid]) {
            profileEntry = [[BDProfileEntry alloc] initWithProfileName:name value:value];
            [[self profileEntriesForSSID:ssid] setObject:profileEntry forKey:name];
        } else {
            // 若已存在且在有效内，则考虑用户ssid、键名、值三元素。若三元素都相同，则不上报。
            if ([profileEntry.name isEqualToString:name] &&
                [profileEntry.valueHash isEqualToString:[BDProfileEntry calcValueHash:value]]) {
                return NO;
            }
        }
    }
    
    // 上报
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeSet];
    }
    return NO;
}

- (BOOL)impl_profileSetOnce:(NSDictionary *)profileDict {
    
    NSString *ssid = self.ssID;
    // 通用类型检查
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    // 流量控制。若已经setOnce过该key，则将其移除出profileDict，不再上报。
    for (NSString *key in validatedProfileDict.allKeys) {
        if ([[self profileNamesForSSID:ssid] containsObject:key]) {
            // 已经存在这个profile名称了，因此移除出profileDict，后续不上报
            [validatedProfileDict removeObjectForKey:key];
        } else {
            // 还不存在这个profile名称，加入集合，后续会上报。
            [[self profileNamesForSSID:ssid] addObject:key];
        }
    }
    
    // 上报
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeSetOnce];
    }
    return NO;
}

- (BOOL)impl_profileUnset:(NSString *)profileName {
    NSString *ssid = self.ssID;
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
    // 通用类型检查.
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    // 键为字符串，值为NSNumber类型。 移除不符合类型检查的KV对。
    for (NSString *key in validatedProfileDict.allKeys) {
        NSObject *value = validatedProfileDict[key];
        // 如果不是NSNumber类型，或者是浮点数，就过滤
        if (![value isKindOfClass:NSNumber.class] || [[(NSNumber *)value stringValue] containsString:@"."]) {
            [validatedProfileDict removeObjectForKey:key];
        }
    }
    
    // 上报
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeIncrement];
    }
    return NO;
}

- (BOOL)impl_profileAppend:(NSDictionary *)profileDict {
    // 通用类型检查。
    NSMutableDictionary *validatedProfileDict = [self validateProfileDict:profileDict];
    
    // Append接口类型检查。value的类型必须为NSString，否则移除。
    for (NSString *key in validatedProfileDict.allKeys) {
        NSObject *value = validatedProfileDict[key];
        
        if (![value isKindOfClass:NSArray.class] && ![value isKindOfClass:NSString.class]) { // value 既不是NSArray，也不是NSString。这种情况移除该KV对。
            [validatedProfileDict removeObjectForKey:key];
        }
        else if ([value isKindOfClass:NSString.class]) {
            // 如果value是NSString，则转为数组，使得上报时value类型统一为数组。
            [validatedProfileDict setObject:@[value] forKey:key];
        }
    }
    
    // 上报
    if (validatedProfileDict.count > 0) {
        return [self reportProfileDict:validatedProfileDict reqType:BDProfileRequestTypeAppend];
    }
    return NO;
}

#ifdef DEBUG
/// 清空Profile流控数据结构，仅用于单元测试
- (void)_resetProfileFlowControlPolicy {
    [self setControledProfileEntries:nil];
    [self setControledProfileNames:nil];
}
#endif

#pragma mark 关联对象
/// 用于profileSet接口流量控制的数据结构. ssid -> KV_DICT
- (NSMutableDictionary <NSString *, NSMutableDictionary *> *)controledProfileEntries {
    if (!objc_getAssociatedObject(self, setFlowControlAK)) {
        [self setControledProfileEntries:[NSMutableDictionary new]];
    }
    return objc_getAssociatedObject(self, setFlowControlAK);
}

- (void)setControledProfileEntries:(NSMutableDictionary <NSString *, NSMutableDictionary *> *)profileEntries {
    objc_setAssociatedObject(self, setFlowControlAK, profileEntries, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// 用于profileSetOnce接口上报控制的数据结构
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
/// 获取对应用户ssid命名空间的数据结构
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

/// 获取对应用户ssid命名空间的数据结构
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
