//
//  CLLocationManagerDelegate+BDAutoTrack.m
//  RangersAppLog
//
//  Created by bytedance on 2022/4/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BDAutoTrackSwizzle.h"
#import "BDAutoTrackApplication.h"
#import "BDCommonDefine.h"
#import "CLLocationManager+AutoTrack.h"


@implementation CLLocationManager (AutoTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    static dispatch_queue_t bd_serialQueue;
    
    dispatch_once(&onceToken, ^{
        bd_serialQueue = dispatch_queue_create([@"com.applog.gps_track" UTF8String], DISPATCH_QUEUE_SERIAL);
        
        BDAutoTrackSwizzle *swizzle = [BDAutoTrackSwizzle new];
        swizzle.originIMP = bd_swizzle_instance_methodWithBlock([self class], @selector(setDelegate:), ^(UITableView *_self, id delegate){
            if (!swizzle.originIMP) {
                return;
            }
            
            if (delegate == nil) {
                ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), nil);
                return;
            }
            
            Class delegateClass = object_getClass(delegate);
            SEL didUpdateLocationsSelector = @selector(locationManager:didUpdateLocations:);
            if (bd_swizzle_has_selector(delegate, didUpdateLocationsSelector)) {
                BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                id delegateBlock = ^void (id delegateSelf, CLLocationManager *manager, NSArray<CLLocation *> *locations) {
                    if (delegateSwizzle.originIMP) {
                        ((void ( *)(id, SEL, CLLocationManager *, NSArray<CLLocation *> *))delegateSwizzle.originIMP)(delegateSelf, didUpdateLocationsSelector, manager, locations);
                    }
                    dispatch_async(bd_serialQueue, ^{
                        CLLocationCoordinate2D coordinate = locations.lastObject.coordinate;
                        [[BDAutoTrackApplication shared] updateAutoTrackGPSLocation:BDAutoTrackGeoCoordinateSystemWGS84 longitude:coordinate.longitude latitude:coordinate.latitude];
                    });
                    
                };
                delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass, didUpdateLocationsSelector, delegateBlock);
            } else {
                BDAutoTrackSwizzle *delegateSwizzle = [BDAutoTrackSwizzle new];
                id delegateBlock = ^id (id delegateSelf, SEL aSelector) {
                    if (delegateSwizzle.originIMP) {
                        return ((id ( *)(id, SEL, SEL))delegateSwizzle.originIMP)(delegateSelf, @selector(forwardingTargetForSelector:), aSelector);
                    }
                    return nil;
                };
                delegateSwizzle.originIMP = bd_swizzle_instance_methodWithBlock(delegateClass, @selector(forwardingTargetForSelector:), delegateBlock);
            }
            
            ((void ( *)(id, SEL, id))swizzle.originIMP)(_self, @selector(setDelegate:), delegate);
        });
    });
}

@end

