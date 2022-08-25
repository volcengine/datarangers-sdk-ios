//
//  BDAutoTrack+OhayooGameTrack.m
//  Applog
//
//  Created by bob on 2019/7/17.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+OhayooGameTrack.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+GameTrack.h"

OhayooCustomHeaderKey OhayooCustomHeaderKeyPackageChannel = @"ohayoo_packagechannel";
OhayooCustomHeaderKey OhayooCustomHeaderKeyZoneID         = @"ohayoo_zoneid";
OhayooCustomHeaderKey OhayooCustomHeaderKeyServerID       = @"ohayoo_serverid";
OhayooCustomHeaderKey OhayooCustomHeaderKeySDKOpenID      = @"ohayoo_sdk_open_id";
OhayooCustomHeaderKey OhayooCustomHeaderKeyUserType       = @"ohayoo_usertype";
OhayooCustomHeaderKey OhayooCustomHeaderKeyRoleID         = @"ohayoo_roleid";
OhayooCustomHeaderKey OhayooCustomHeaderKeyLevel          = @"ohayoo_level";

static NSString * const GTGameEventGameInitInfo         = @"gt_init_info";
static NSString * const kGTGameParameterSceneID         = @"scene_id";
static NSString * const kGTGameParameterSceneLev        = @"scene_lev";
static NSString * const kGTGameParameterCoinType        = @"coin_type";
static NSString * const kGTGameParameterCoinLeft        = @"coin_left";
static NSString * const kGTGameParameterRoleID          = @"role_id";

#pragma mark - OhayooGameTrack
@implementation BDAutoTrack (OhayooGameTrack)

- (void)gameInitInfoEventWithLevel:(NSInteger)level
                           sceneID:(NSInteger)sceneID
                          sceneLev:(NSInteger)sceneLev
                          coinType:(NSString *)coinType
                          coinLeft:(NSInteger)coinLeft
                            roleId:(NSString *)roleId
                       otherParams:(NSDictionary *)otherParams {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    
    [params setValue:@(level) forKey:kGTGameParameterLevel];
    [params setValue:@(sceneID) forKey:kGTGameParameterSceneID];
    [params setValue:@(sceneLev) forKey:kGTGameParameterSceneLev];
    [params setValue:coinType forKey:kGTGameParameterCoinType];
    [params setValue:@(coinLeft) forKey:kGTGameParameterCoinLeft];
    [params setValue:roleId forKey:kGTGameParameterRoleID];
    
    [self eventV3:GTGameEventGameInitInfo params:params];
}

- (void)ohayooHeaderSetObject:(NSObject *)object forKey:(OhayooCustomHeaderKey)key {
    [self setCustomHeaderValue:object forKey:key];
}

- (void)ohayooHeaderRemoveObjectForKey:(OhayooCustomHeaderKey)key {
    [self removeCustomHeaderValueForKey:key];
}
@end


#pragma mark - SharedOhayooGameTrack
@implementation BDAutoTrack (SharedOhayooGameTrack)

+ (void)gameInitInfoEventWithLevel:(NSInteger)level
                           sceneID:(NSInteger)sceneID
                          sceneLev:(NSInteger)sceneLev
                          coinType:(NSString *)coinType
                          coinLeft:(NSInteger)coinLeft
                            roleId:(NSString *)roleId
                       otherParams:(nullable NSDictionary *)otherParams {
    
    [[BDAutoTrack sharedTrack] gameInitInfoEventWithLevel:level
                              sceneID:sceneID
                             sceneLev:sceneLev
                             coinType:coinType
                             coinLeft:coinLeft
                               roleId:roleId
                          otherParams:otherParams];
}

+ (void)ohayooHeaderSetObject:(NSObject *)object forKey:(OhayooCustomHeaderKey)key {
    [[self sharedTrack] ohayooHeaderSetObject:object forKey:key];
}

+ (void)ohayooHeaderRemoveObjectForKey:(OhayooCustomHeaderKey)key {
    [[self sharedTrack] ohayooHeaderRemoveObjectForKey:key];
}

@end
