//
//  BDAutoTrackCellular.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/26.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#if TARGET_OS_IOS

#import "BDAutoTrackCellular.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTCellularData.h>

@interface BDAutoTrackCellular ()<CTTelephonyNetworkInfoDelegate> {
    NSLock *syncLock;
    NSDictionary *  _currentCarrier;
}

@property (nonatomic, copy) NSString *celluarDataServiceIdeintifier;
@property (nonatomic, assign) BDAutoTrackConnectionType connectionType;

@end

@implementation BDAutoTrackCellular

+ (instancetype)sharedInstance {
    static BDAutoTrackCellular *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

+ (CTTelephonyNetworkInfo *)telephonyNetworkInfo
{
    static CTTelephonyNetworkInfo *telephony;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        telephony = [[CTTelephonyNetworkInfo alloc] init];
    });
    return telephony;
}

//+ (CTCellularData *)cellularData
//{
//    static CTCellularData *cellularData;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        cellularData = [[CTCellularData alloc] init];
//    });
//    return cellularData;
//}


- (instancetype)init
{
    if (self = [super init]) {
        syncLock = [NSLock new];
        [self onAccessTechnologyDidChange]; //init connectionType
        if (@available(iOS 13.0, *)) {
            [self dataServiceIdentifierDidChange:[[self class] telephonyNetworkInfo].dataServiceIdentifier];
            [[self class] telephonyNetworkInfo].delegate = self;
        } else {
            
        }
        [self addNotificationObservers];
    }
    return self;
}


- (void)addNotificationObservers
{
    if (@available(iOS 12.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccessTechnologyDidChange) name:CTServiceRadioAccessTechnologyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccessTechnologyDidChange) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    }
}

- (void)onAccessTechnologyDidChange
{
    NSString *tech = [self currentRadioAccessTechnology];
    
    BDAutoTrackConnectionType type = BDAutoTrackConnectionTypeNone;
    if (tech.length > 0) {
        if ([tech isEqualToString:@"CTRadioAccessTechnologyNR"]
            ||[tech isEqualToString:@"CTRadioAccessTechnologyNRNSA"]) {
            type = BDAutoTrackConnectionType5G;
        } else if ([tech isEqualToString:CTRadioAccessTechnologyLTE]) {
            type = BDAutoTrackConnectionType4G;
        } else if ([tech isEqualToString:CTRadioAccessTechnologyWCDMA]
                   || [tech isEqualToString:CTRadioAccessTechnologyHSDPA]
                   || [tech isEqualToString:CTRadioAccessTechnologyHSUPA]
                   || [tech isEqualToString:CTRadioAccessTechnologyCDMA1x]
                   || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]
                   || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]
                   || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]
                   || [tech isEqualToString:CTRadioAccessTechnologyeHRPD]) {
            type = BDAutoTrackConnectionType3G;
        } else if ([tech isEqualToString:CTRadioAccessTechnologyGPRS] ||[tech isEqualToString:CTRadioAccessTechnologyEdge]) {
            type = BDAutoTrackConnectionType2G;
        } else {
            type = BDAutoTrackConnectionTypeMobile;
        }
    }
    self.connectionType = type;
    
}


#pragma mark -
- (void)dataServiceIdentifierDidChange:(NSString *)identifier
{
    self.celluarDataServiceIdeintifier = identifier;
    [self _updateCarrier];
}



#pragma mark - Private

- (NSDictionary *)carrierToJSONObject:(CTCarrier *)carrier
{
    if (!carrier) {
        return @{};
    }
    return @{@"carrierName":carrier.carrierName?:@"",
             @"mobileCountryCode":carrier.mobileCountryCode?:@"",
             @"mobileNetworkCode":carrier.mobileNetworkCode?:@"",
             @"isoCountryCode":carrier.isoCountryCode?:@""
             };
}

- (void)_updateCarrier
{
    CTCarrier *carrier = [self currentCTCarrier];
    if (carrier) {
        [syncLock lock];
        _currentCarrier = [self carrierToJSONObject:carrier];
        [syncLock unlock];
    }
}

- (void)_updateConnection
{
    
}

- (CTCarrier *)currentCTCarrier
{
    CTCarrier *carrier;
    if (@available(iOS 13.0, *)) {
        if (self.celluarDataServiceIdeintifier) {
            carrier = [[[self class].telephonyNetworkInfo serviceSubscriberCellularProviders] objectForKey:self.celluarDataServiceIdeintifier];
        }
    }
    return carrier;
}

- (NSString *)currentRadioAccessTechnology
{
    NSString *accessTechnology = nil;
    CTTelephonyNetworkInfo *info = [[self class] telephonyNetworkInfo];
    if (@available(iOS 12.0, *)) {
        if (@available(iOS 13.0, *)) {
            if ([self.celluarDataServiceIdeintifier length] > 0) {
                accessTechnology = [info.serviceCurrentRadioAccessTechnology objectForKey:self.celluarDataServiceIdeintifier];
            }
            if (accessTechnology.length == 0) {
                accessTechnology = [info.serviceCurrentRadioAccessTechnology allValues].firstObject;
            }
        }
    } else {
        // Fallback on earlier versions
        accessTechnology = info.currentRadioAccessTechnology;
    }
    return accessTechnology;
}

#pragma mark - Public

- (BDAutoTrackConnectionType)connection
{
    return 0;
}

- (id)carrier
{
    id carrier;
    [syncLock lock];
    carrier = [_currentCarrier copy];
    [syncLock unlock];
    return carrier;
}



@end

#endif
