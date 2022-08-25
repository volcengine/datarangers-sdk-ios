#import "BDAutoTrackReachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
#import <ifaddrs.h>
#import <netdb.h>
#import <notify_keys.h>

NSNotificationName const BDAutoTrackReachabilityChangedNotification = @"BDAutoTrackReachabilityChangedNotification";

static BDAutoTrackReachabilityStatus networkStatusForFlags(SCNetworkReachabilityFlags flags) {
    
    BDAutoTrackReachabilityStatus returnValue = BDAutoTrackReachabilityStatusNotReachable;
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0){
        return returnValue;
    }

    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        returnValue = BDAutoTrackReachabilityStatusReachableViaWiFi;
    }

    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0)
         || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            returnValue = BDAutoTrackReachabilityStatusReachableViaWiFi;
        }
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        returnValue = BDAutoTrackReachabilityStatusReachableViaWWAN;
    }

    return returnValue;
}

typedef void (^BDAutoTrackReachabilityStatusBlock)(BDAutoTrackReachabilityStatus status);

static void BDAutoTrackReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    BDAutoTrackReachabilityStatusBlock block =  (__bridge BDAutoTrackReachabilityStatusBlock)info;
    BDAutoTrackReachabilityStatus status = networkStatusForFlags(flags);
    if (block) {
        block(status);
    }
}

static const void * BDAutoTrackReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void BDAutoTrackReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface BDAutoTrackReachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef  reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t reachabilityQueue;

@property (atomic, assign) BDAutoTrackReachabilityStatus reachabilityStatus;

@end

@implementation BDAutoTrackReachability {
    
    
}

+ (instancetype)reachability {
    
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,(const struct sockaddr *)&address);
    BDAutoTrackReachability *reachability = [[self alloc] initWithReachabilityRef:reachabilityRef];
    if (reachabilityRef != NULL) {
        CFRelease(reachabilityRef);
    }
    return reachability;
}

- (BDAutoTrackReachabilityStatus)status
{
    return self.reachabilityStatus;
}

- (instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef
{
    if (self = [super init]) {
        if (reachabilityRef != NULL) {
            self.reachabilityRef = CFRetain(reachabilityRef);
            SCNetworkReachabilityFlags flags;
            if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
                BDAutoTrackReachabilityStatus status = networkStatusForFlags(flags);
                self.reachabilityStatus = status;
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [self stopNotifier];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
}

- (void)startNotifier {
    [self stopNotifier];
    if (self.reachabilityRef == NULL) {
        return;
    }
    __weak __typeof(self)weakSelf = self;
    BDAutoTrackReachabilityStatusBlock callback = ^(BDAutoTrackReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf && strongSelf.reachabilityStatus != status) {
            strongSelf.reachabilityStatus = status;
            [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackReachabilityChangedNotification
                                                                object:nil];
            
        }
    };
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, BDAutoTrackReachabilityRetainCallback, BDAutoTrackReachabilityReleaseCallback, NULL};
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, BDAutoTrackReachabilityCallback, &context)) {
        SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    }
}

- (void)stopNotifier {
    if (self.reachabilityRef == NULL) {
        return;
    }
    SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (BOOL)isNetworkConnected {
    return self.reachabilityStatus > BDAutoTrackReachabilityStatusNotReachable;
}

@end

