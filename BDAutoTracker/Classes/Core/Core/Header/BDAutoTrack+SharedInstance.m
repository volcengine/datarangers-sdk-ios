//
//  BDAutoTrackHolder.m
//  RangersAppLog
//
//  Created by bob on 2019/10/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack.h"
#import "BDAutoTrack+SharedInstance.h"
#import "BDTrackerCoreConstants.h"

#import "BDAutoTrack+Game.h"
#import "BDAutoTrack+GameTrack.h"
#import "BDAutoTrack+Special.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrack+OhayooGameTrack.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDAutoTrackLocalConfigService.h"

#if __has_include("RALSecML.h")
#import "RALSecML.h"
#endif

static BDAutoTrack *track = nil;
static BDAutoTrackCustomHeaderBlock storedCustomHeader = nil;
static BDAutoTrackRequestURLBlock storedRequestURLBlock = nil;
static BDAutoTrackRequestHostBlock storedRequestHostBlock = nil;

/// 纯接口转发，没有逻辑
@implementation BDAutoTrack (SharedInstance)

#pragma mark - 初始化与启动单例
+ (void)startTrackWithConfig:(BDAutoTrackConfig *)config {
    [BDAutoTrack sharedTrackWithConfig:config];
    [BDAutoTrack startTrack];
}

+ (void)sharedTrackWithConfig:(BDAutoTrackConfig *)config {
    track = [BDAutoTrack trackWithConfig:config];
    [track setCustomHeaderBlock:storedCustomHeader];
    [track setRequestURLBlock:storedRequestURLBlock];
    [track setRequestHostBlock:storedRequestHostBlock];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* 如果引入了安全SDK子库，则启动安全SDK */
        Class RALSecML = NSClassFromString(@"RALSecML");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if (RALSecML && [RALSecML respondsToSelector:@selector(bootMSSecML)]) {
            [RALSecML performSelector:@selector(bootMSSecML)];
        }
#pragma clang diagnostic pop
    });
}

+ (void)startTrack {
    [track startTrack];
}

+ (instancetype)sharedTrack {
    return track;
}

#pragma mark - class property
+ (NSString *)appID {
    return track.appID;
}

+ (NSString *)rangersDeviceID {
    return track.rangersDeviceID;
}

+ (NSString *)installID {
    return track.installID;
}

+ (NSString *)ssID {
    return track.ssID;
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat:@"%@", @(BDAutoTrackerSDKVersion)];
}

+ (NSString *)userUniqueID {
    return track.userUniqueID;
}

#pragma mark - public method
+ (void)setUserAgent:(NSString *)userAgent {
    [track setUserAgent:userAgent];
}

+ (BOOL)setCurrentUserUniqueID:(NSString *)uniqueID {
    return [track setCurrentUserUniqueID:uniqueID];
}

+ (void)clearUserUniqueID {
    [track clearUserUniqueID];
}

+ (BOOL)sendRegisterRequestWithRegisteringUserUniqueID:(NSString *)registeringUserUniqueID {
    return [track sendRegisterRequestWithRegisteringUserUniqueID:registeringUserUniqueID];
}

+ (BOOL)sendRegisterRequest APPLOG_API_AVALIABLE(5.6.3) {
    return [track sendRegisterRequest];
}

+ (void)setServiceVendor:(BDAutoTrackServiceVendor)serviceVendor {
    [track setServiceVendor:serviceVendor];
}

+ (void)setRequestURLBlock:(BDAutoTrackRequestURLBlock)requestURLBlock {
    storedRequestURLBlock = [requestURLBlock copy];
    [track setRequestURLBlock:requestURLBlock];
}

+ (void)setAppRegion:(NSString *)appRegion {
    [track setAppRegion:appRegion];
}

+ (void)setAppTouchPoint:(NSString *)appTouchPoint {
    [track setAppTouchPoint:appTouchPoint];
}

+ (void)setRequestHostBlock:(BDAutoTrackRequestHostBlock)requestHostBlock {
    storedRequestHostBlock = [requestHostBlock copy];
    [track setRequestHostBlock:requestHostBlock];
}

+ (void)setAppLauguage:(NSString *)appLauguage {
    [track setAppLauguage:appLauguage];
}

+ (void)setCustomHeaderValue:(id)value forKey:(NSString *)key {
    [track setCustomHeaderValue:value forKey:key];
}

+ (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary {
    [track setCustomHeaderWithDictionary:dictionary];
}

+ (void)removeCustomHeaderValueForKey:(NSString *)key {
    [track removeCustomHeaderValueForKey:key];
}

+ (void)setCustomHeaderBlock:(BDAutoTrackCustomHeaderBlock)customHeaderBlock {
    storedCustomHeader = [customHeaderBlock copy];
    [track setCustomHeaderBlock:customHeaderBlock];
}

+ (BOOL)eventV3:(NSString *)event params:(NSDictionary *)params {
    if (track == nil) {
        return NO;
    }
    
    return [track eventV3:event params:params];
}

+ (id)ABTestConfigValueForKey:(NSString *)key defaultValue:(id)defaultValue {
    if (track == nil) {
        return defaultValue;
    }
    
    return [track ABTestConfigValueForKey:key defaultValue:defaultValue];
}

+ (nullable id)ABTestConfigValueSyncForKey:(NSString *)key defaultValue:(nullable id)defaultValue {
    return [track ABTestConfigValueSyncForKey:key defaultValue:defaultValue];
}

+ (void)setExternalABVersion:(NSString *)versions {
    [track setExternalABVersion:versions];
}

+ (NSString *)abVids {
    return [track abVids];
}

+ (NSString *)allAbVids {
    return [track allAbVids];
}

+ (NSDictionary *)allABTestConfigs {
    return [track allABTestConfigs];
}

+ (NSDictionary *)allABTestConfigs2 {
    return [track allABTestConfigs2];
}

+ (nullable NSString *)abVidsSync {
    return [[self sharedTrack] abVidsSync];
}

+ (nullable NSString *)allAbVidsSync {
    return [[self sharedTrack] allAbVidsSync];
}

+ (nullable NSDictionary *)allABTestConfigsSync {
    return [[self sharedTrack] allABTestConfigsSync];
}

+ (void)pullABTestConfigs {
    [[self sharedTrack] pullABTestConfigs];
}

/// 上报数据库文件中的埋点数据。不区分实例。转发到实例方法是为了方便实例调用。
+ (void)flush {
    [track flushWithTimeInterval:10];
}

#pragma mark - ALink
+ (void)setALinkRoutingDelegate:(id<BDAutoTrackAlinkRouting>)ALinkRoutingDelegate {
    return [track setALinkRoutingDelegate:ALinkRoutingDelegate];
}

+ (BOOL)continueALinkActivityWithURL:(NSURL *)ALinkURL {
    return [track continueALinkActivityWithURL:ALinkURL];
}

@end


#pragma mark - Game

@implementation BDAutoTrack (SharedGame)

+ (void)registerEventByMethod:(NSString *)method isSuccess:(BOOL)isSuccess {
    [track registerEventByMethod:method isSuccess:isSuccess];
}

+ (void)loginEventByMethod:(NSString *)method isSuccess:(BOOL)isSuccess {
    [track loginEventByMethod:method isSuccess:isSuccess];
}

+ (void)accessAccountEventByType:(NSString *)type isSuccess:(BOOL)isSuccess {
    [track accessAccountEventByType:type isSuccess:isSuccess];
}

+ (void)questEventWithQuestID:(NSString *)questID
                    questType:(NSString *)type
                    questName:(NSString *)name
                   questNumer:(NSUInteger)number
                  description:(NSString *)desc
                    isSuccess:(BOOL)isSuccess {
    [track questEventWithQuestID:questID
                       questType:type
                       questName:name
                      questNumer:number
                     description:desc
                       isSuccess:isSuccess];
}

+ (void)updateLevelEventWithLevel:(NSUInteger)level {
    [track updateLevelEventWithLevel:level];
}

+ (void)viewContentEventWithContentType:(NSString *)type
                            contentName:(NSString *)name
                              contentID:(NSString *)contentID {
    [track viewContentEventWithContentType:type
                               contentName:name
                                 contentID:contentID];
}

+ (void)addCartEventWithContentType:(NSString *)type
                        contentName:(NSString *)name
                          contentID:(NSString *)contentID
                      contentNumber:(NSUInteger)number
                          isSuccess:(BOOL)isSuccess {
    [track addCartEventWithContentType:type
                           contentName:name
                             contentID:contentID
                         contentNumber:number
                             isSuccess:isSuccess];
}

+ (void)checkoutEventWithContentType:(NSString *)type
                         contentName:(NSString *)name
                           contentID:(NSString *)contentID
                       contentNumber:(NSUInteger)number
                   isVirtualCurrency:(BOOL)isVirtualCurrency
                     virtualCurrency:(NSString *)virtualCurrency
                            currency:(NSString *)currency
                     currency_amount:(unsigned long long)amount
                           isSuccess:(BOOL)isSuccess {
    [track checkoutEventWithContentType:type
                            contentName:name
                              contentID:contentID
                          contentNumber:number
                      isVirtualCurrency:isVirtualCurrency
                        virtualCurrency:virtualCurrency
                               currency:currency
                        currency_amount:amount
                              isSuccess:isSuccess];
}

+ (void)purchaseEventWithContentType:(NSString *)type
                         contentName:(NSString *)name
                           contentID:(NSString *)contentID
                       contentNumber:(NSUInteger)number
                      paymentChannel:(NSString *)channel
                            currency:(NSString *)currency
                     currency_amount:(unsigned long long)amount
                           isSuccess:(BOOL)isSuccess {
    [track purchaseEventWithContentType:type
                            contentName:name
                              contentID:contentID
                          contentNumber:number
                         paymentChannel:channel
                               currency:currency
                        currency_amount:amount
                              isSuccess:isSuccess];
}

+ (void)accessPaymentChannelEventByChannel:(NSString *)channel isSuccess:(BOOL)isSuccess {
    [track accessPaymentChannelEventByChannel:channel isSuccess:isSuccess];
}

+ (void)createGameRoleEventByID:(NSString *)roleID {
    [track createGameRoleEventByID:roleID];
}

+ (void)addToFavouriteEventWithContentType:(NSString *)type
                               contentName:(NSString *)name
                                 contentID:(NSString *)contentID
                             contentNumber:(NSUInteger)number
                                 isSuccess:(BOOL)isSuccess {
    [track addToFavouriteEventWithContentType:type
                                  contentName:name
                                    contentID:contentID
                                contentNumber:number
                                    isSuccess:isSuccess];
}

@end


#pragma mark - GTGame

@implementation BDAutoTrack (SharedGameTrack)

+ (void)adButtonClickEventWithADType:(NSString *)adType
                        positionType:(NSString *)positionType
                            position:(NSString *)position
                         otherParams:(nullable NSDictionary *)otherParams {
    [track adButtonClickEventWithADType:adType
                           positionType:positionType
                               position:position
                            otherParams:otherParams];
}

+ (void)adShowEventWithADType:(NSString *)adType
                 positionType:(NSString *)positionType
                     position:(NSString *)position
                  otherParams:(nullable NSDictionary *)otherParams{
    [track adShowEventWithADType:adType
                    positionType:positionType
                        position:position
                     otherParams:otherParams];
}

+ (void)adShowEndEventWithADType:(NSString *)adType
                    positionType:(NSString *)positionType
                        position:(NSString *)position
                          result:(NSString *)result
                     otherParams:(nullable NSDictionary *)otherParams {
    [track adShowEndEventWithADType:adType
                       positionType:positionType
                           position:position
                             result:result
                        otherParams:otherParams];
}

+ (void)levelUpEventWithLevel:(NSInteger)level
                          exp:(NSInteger)exp
                       method:(NSString *)method
                   afterLevel:(NSInteger)afterLevel
                  otherParams:(nullable NSDictionary *)otherParams {
    [track levelUpEventWithLevel:level
                             exp:exp
                          method:method
                      afterLevel:afterLevel
                     otherParams:otherParams];
}

+ (void)startPlayEventWithName:(NSString *)ecTypeName
                   otherParams:(nullable NSDictionary *)otherParams {
    [track startPlayEventWithName:ecTypeName otherParams:otherParams];
}

+ (void)endPlayEventWithName:(NSString *)ecTypeName
                      result:(NSString *)result
                    duration:(NSInteger)duration
                 otherParams:(nullable NSDictionary *)otherParams {
    [track endPlayEventWithName:ecTypeName
                         result:result
                       duration:duration
                    otherParams:otherParams];
}

+ (void)getCoinsEventWitType:(NSString *)coinType
                      method:(NSString *)method
                  coinNumber:(NSInteger)number
                 otherParams:(nullable NSDictionary *)otherParams {
    [track getCoinsEventWitType:coinType
                         method:method
                     coinNumber:number
                    otherParams:otherParams];
}

+ (void)costCoinsEventWitType:(NSString *)coinType
                       method:(NSString *)method
                   coinNumber:(NSInteger)number
                  otherParams:(nullable NSDictionary *)otherParams {
    [track costCoinsEventWitType:coinType
                          method:method
                      coinNumber:number
                     otherParams:otherParams];
}

+ (void)purchaseEventWithContentType:(NSString *)contentType
                         contentName:(NSString *)contentName
                           contentID:(NSString *)contentID
                          contentNum:(NSInteger)contentNum
                             channel:(NSString *)channel
                            currency:(NSString *)currency
                           isSuccess:(NSString *)isSuccess
                      currencyAmount:(NSInteger)currencyAmount
                         otherParams:(nullable NSDictionary *)otherParams {
    [track purchaseEventWithContentType:contentType
                            contentName:contentName
                              contentID:contentID
                             contentNum:contentNum
                                channel:channel
                               currency:currency
                              isSuccess:isSuccess
                         currencyAmount:currencyAmount
                            otherParams:otherParams];
}

+ (void)gameInitInfoEventWithLevel:(NSInteger)level
                          coinType:(NSString *)coinType
                          coinLeft:(NSInteger)coinLeft
                       otherParams:(nullable NSDictionary *)otherParams {
    [track gameInitInfoEventWithLevel:level
                             coinType:coinType
                             coinLeft:coinLeft
                          otherParams:otherParams];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma mark - Special

@implementation BDAutoTrack (SharedSpecial)


+ (BOOL)eventV3:(NSString *)event
         params:(NSDictionary *)params
  specialParams:(NSDictionary *)specialParams {

    return [track eventV3:event params:params specialParams:specialParams];
}

/// 视频云点播SDK
+ (BOOL)customEvent:(NSString *)category params:(NSDictionary *)params {
    return [track customEvent:category params:params];
}

@end

#pragma clang diagnostic pop
