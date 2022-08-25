//
//  VEInstallCelluar.m
//  Masonry
//
//  Created by KiBen on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallCellular.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTCellularData.h>

#ifndef VE_Lock
#define VE_Lock(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef VE_Unlock
#define VE_Unlock(lock) dispatch_semaphore_signal(lock);
#endif

/// 解析流量连接类型(None, 5G, 4G, 3G, 2G)
static VEInstallCellularConnectionType ParseRadioAccessTechnology(NSString * tech) {
    if (tech.length < 1) return VEInstallCellularConnectionTypeNone;
#if __IPHONE_14_0
    if (@available(iOS 14.1, *)) {
// 苹果存在Bug：这两个符号，在iOS 14.1真机上才存在，但是SDK的头文件标注的available是iOS 14.0+，会导致运行时Crash，参考FB8879347
// 之前把@available改为14.1了，以为解决了。但是发现Lark居然14.2也有Crash。好吧直接学tt_pods_reachability hardcode字符串
        #define CTRadioAccessTechnologyNR @"CTRadioAccessTechnologyNR"
        #define CTRadioAccessTechnologyNRNSA @"CTRadioAccessTechnologyNRNSA"
        if ([tech isEqualToString:CTRadioAccessTechnologyNR]
            ||[tech isEqualToString:CTRadioAccessTechnologyNRNSA]) {
            return VEInstallCellularConnectionType5G;
        }
        #undef CTRadioAccessTechnologyNR
        #undef CTRadioAccessTechnologyNRNSA
    }
#endif
    if ([tech isEqualToString:CTRadioAccessTechnologyLTE]) {
        return VEInstallCellularConnectionType4G;
    }

    if ([tech isEqualToString:CTRadioAccessTechnologyWCDMA]
        || [tech isEqualToString:CTRadioAccessTechnologyHSDPA]
        || [tech isEqualToString:CTRadioAccessTechnologyHSUPA]
        || [tech isEqualToString:CTRadioAccessTechnologyCDMA1x]
        || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]
        || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]
        || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]
        || [tech isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return VEInstallCellularConnectionType3G;
    }

    if ([tech isEqualToString:CTRadioAccessTechnologyGPRS] ||[tech isEqualToString:CTRadioAccessTechnologyEdge]) {
        return VEInstallCellularConnectionType2G;
    }
    
    return VEInstallCellularConnectionTypeUnknown;
}

@interface VEInstallCellular ()
#if __IPHONE_13_0
<CTTelephonyNetworkInfoDelegate>
#endif

@property (class, nonatomic, strong, readonly) CTTelephonyNetworkInfo *telephoneInfo;
@property (nonatomic, assign) BOOL usingCellularServiceAPI;
@property (nonatomic, strong) dispatch_semaphore_t serviceCurrentRadioAccessTechnologyLock;
@property (nonatomic, strong) dispatch_semaphore_t serviceSubscriberCellularProvidersLock;

///
@property (nonatomic, assign) NSUInteger cellularCount;
@property (nonatomic, assign) VEInstallCellularConnectionType primaryCellularConnectionType;
@property (nonatomic, assign) VEInstallCellularConnectionType secondaryCellularConnectionType;
@property (nonatomic, copy) NSString *primaryRadioAccessTechnology;
@property (nonatomic, copy) NSString *secondaryRadioAccessTechnology;

///
@property (nonatomic, copy) NSString *primaryIdentifier;
@property (nonatomic, copy) NSString *secondaryIdentifier;
@property (nonatomic, strong) CTCarrier *primaryCarrier;
@property (nonatomic, strong) CTCarrier *secondaryCarrier;

/// iOS 13+为数据流量卡的ID。iOS 13 以下为nil。
@property(nonatomic, copy) NSString *dataServiceIdentifier;

@end

@implementation VEInstallCellular

+ (CTTelephonyNetworkInfo *)telephoneInfo {
    static dispatch_once_t onceToken;
    static CTTelephonyNetworkInfo *telephoneInfo = nil;
    dispatch_once(&onceToken, ^{
        telephoneInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    
    return telephoneInfo;
}

+ (CTCellularData *)cellularData  API_AVAILABLE(ios(9.0)){
    static dispatch_once_t onceToken;
    static CTCellularData *cellularData = nil;
    dispatch_once(&onceToken, ^{
        cellularData = [CTCellularData new];
    });
    
    return cellularData;
}

+ (instancetype)sharedInstance {
    static VEInstallCellular *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cellularCount = 1;
        self.primaryCellularConnectionType = VEInstallCellularConnectionTypeNone;
        self.secondaryCellularConnectionType = VEInstallCellularConnectionTypeNone;
        self.serviceCurrentRadioAccessTechnologyLock = dispatch_semaphore_create(1);
        self.serviceSubscriberCellularProvidersLock = dispatch_semaphore_create(1);
        
        /// 兼容Hack，仅仅在iOS 12.0.0 Beta版本，不包含双卡API，单独Hack处理，待iOS 12普及率上来后删除
        /// 最新发现，单卡iPhone在iOS 12.0版本上，serviceSubscriberCellularProviders方法返回nil，因此也需要过滤，指定到iOS 12.1+
        /* 注册运营商信息变动通知 */
        if (@available(iOS 14.0, *)) {
            self.usingCellularServiceAPI = YES;
            [self updateServiceCellularConnectionType];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onServiceRadioAccessTechnologyDidChange)
                                                         name:CTServiceRadioAccessTechnologyDidChangeNotification
                                                       object:nil];
        }
        else {
            [self updateCellularConnectionType];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(onRadioAccessTechnologyDidChange)
                                                         name:CTRadioAccessTechnologyDidChangeNotification
                                                       object:nil];
            
            
        }
        if (@available(iOS 12.1, *)) {
            //iOS 12-13用新API
            [self updateCarrierProviders];
            VEInstallCellular.telephoneInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = ^(NSString *serviceIdentifier) {
                [[VEInstallCellular sharedInstance] updateCarrierProviders];
            };
        }else{
            //iOS12以下用旧的
            self.primaryCarrier = VEInstallCellular.telephoneInfo.subscriberCellularProvider;
            VEInstallCellular.telephoneInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *carrier) {
                [VEInstallCellular sharedInstance].primaryCarrier = carrier;
            };
        }
        
#if __IPHONE_13_0
        /* 流量卡切换后回调 */
        if (@available (iOS 13, *)) {
            self.dataServiceIdentifier = [VEInstallCellular.telephoneInfo dataServiceIdentifier];
            VEInstallCellular.telephoneInfo.delegate = self;
        }
#endif
    }
    
    return self;
}


#pragma mark - Public API
- (VEInstallCellularConnectionType)cellularConnectionTypeForService:(VEInstallCellularServiceType)service {
    if (self.usingCellularServiceAPI
        && service == VEInstallCellularServiceTypeSecondary
        && self.cellularCount > 1) {
        return self.secondaryCellularConnectionType;
    } else {
        return self.primaryCellularConnectionType;
    }
}

- (CTCarrier *)carrierForService:(VEInstallCellularServiceType)service {
    if (self.usingCellularServiceAPI
        && service == VEInstallCellularServiceTypeSecondary
        && self.cellularCount > 1) {
        return self.secondaryCarrier;
    } else {
        return self.primaryCarrier;
    }
}

- (VEInstallCellularServiceType)currentDataServiceType {
    if (self.cellularCount < 1) {
        return VEInstallCellularServiceTypeNone;
    }
    
    if (self.usingCellularServiceAPI
        && self.secondaryIdentifier != nil
        && [self.dataServiceIdentifier isEqualToString:self.secondaryIdentifier]) {
        
        return VEInstallCellularServiceTypeSecondary;
    }
    
    return VEInstallCellularServiceTypePrimary;
}


#pragma mark - iOS12.1+ 的算法
- (void)onServiceRadioAccessTechnologyDidChange API_AVAILABLE(ios(12.0)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateServiceCellularConnectionType];
    });
}

- (void)updateServiceCellularConnectionType API_AVAILABLE(ios(12.0)) {
    if (VEInstallCellular.telephoneInfo == nil) {
        return;
    }
    
    VE_Lock(self.serviceCurrentRadioAccessTechnologyLock);
    //iOS 12/13可能会崩溃
    NSDictionary<NSString *,NSString *> *serviceCurrentRadioAccessTechnology = [[NSDictionary alloc] initWithDictionary:VEInstallCellular.telephoneInfo.serviceCurrentRadioAccessTechnology copyItems:YES];
    VE_Unlock(self.serviceCurrentRadioAccessTechnologyLock);
    NSArray<NSString *> *keys = serviceCurrentRadioAccessTechnology.allKeys;
    self.cellularCount = keys.count;
    if (keys.count < 1) {
        return;
    }
    /// 使用sort可能会有坑(主卡副卡key苹果没有说明)，目前不怕，以后再改
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSString * primaryIdentifier = [keys firstObject];
    NSString * seconaryIdentifier = [keys lastObject];
    
    
    NSString *primaryRadioAccessTechnology = [serviceCurrentRadioAccessTechnology objectForKey:primaryIdentifier];   // e.g. CTRadioAccessTechnologyLTE
    NSString *secondaryRadioAccessTechnology = [serviceCurrentRadioAccessTechnology objectForKey:seconaryIdentifier];
    
    if (![self.primaryRadioAccessTechnology isEqualToString:primaryRadioAccessTechnology]) {
        self.primaryRadioAccessTechnology = primaryRadioAccessTechnology;
        self.primaryCellularConnectionType = ParseRadioAccessTechnology(primaryRadioAccessTechnology);
    }
    
    if (self.cellularCount > 1
        && ![self.secondaryRadioAccessTechnology isEqualToString:secondaryRadioAccessTechnology]) {
        self.secondaryRadioAccessTechnology = secondaryRadioAccessTechnology;
        self.secondaryCellularConnectionType = ParseRadioAccessTechnology(secondaryRadioAccessTechnology);
    }
}

- (void)updateCarrierProviders  API_AVAILABLE(ios(12.0)) {
    if (VEInstallCellular.telephoneInfo == nil) {
        return;
    }
    
    /* Update self.cellularCount */
    VE_Lock(self.serviceSubscriberCellularProvidersLock);
    NSDictionary<NSString *,CTCarrier *> *serviceSubscriberCellularProviders = [VEInstallCellular.telephoneInfo.serviceSubscriberCellularProviders copy];
    VE_Unlock(self.serviceSubscriberCellularProvidersLock);
    NSArray<NSString *> *keys = serviceSubscriberCellularProviders.allKeys;
    self.cellularCount = keys.count;
    if (keys.count < 1) {
        return;
    }
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    
    
    /* Update self.primaryIdentifier, self.primaryCarrier
     * Update self.secondaryIdentifier, self.secondaryCarrier (if the phone has more than 1 card)
     */
    NSString * primaryIdentifier = [keys firstObject];
    self.primaryIdentifier = primaryIdentifier;
    self.primaryCarrier = [serviceSubscriberCellularProviders objectForKey:primaryIdentifier];
    
    if (self.cellularCount > 1) {
        NSString * seconaryIdentifier = [keys lastObject];
        self.secondaryIdentifier = seconaryIdentifier;
        self.secondaryCarrier = [serviceSubscriberCellularProviders objectForKey:seconaryIdentifier];
    }
}

#pragma mark CTTelephonyNetworkInfoDelegate
/// 流量卡切换后回调 (iOS 13+)
- (void)dataServiceIdentifierDidChange:(NSString *)identifier  API_AVAILABLE(ios(13.0)) {
    self.dataServiceIdentifier = identifier;
}

#pragma mark - iOS 12以下的算法
- (void)onRadioAccessTechnologyDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCellularConnectionType];
    });
}

- (void)updateCellularConnectionType {
    if (VEInstallCellular.telephoneInfo == nil) {
        return;
    }
    
    NSString *currentRadioAccessTechnology = [VEInstallCellular.telephoneInfo.currentRadioAccessTechnology copy];
    if (currentRadioAccessTechnology == nil
        || [self.primaryRadioAccessTechnology isEqualToString:currentRadioAccessTechnology]) {
        return;
    }
    self.primaryRadioAccessTechnology = currentRadioAccessTechnology;
    self.primaryCellularConnectionType = ParseRadioAccessTechnology(currentRadioAccessTechnology);
}

@end
