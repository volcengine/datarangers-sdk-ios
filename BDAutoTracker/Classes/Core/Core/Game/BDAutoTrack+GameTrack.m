//
//  BDAutoTrack+GameTrack.m
//  Applog
//
//  Created by bob on 2019/7/17.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+GameTrack.h"
#import "BDAutoTrackUtility.h"


#pragma mark - common
NSString * const kGTGameParameterLevel                  = @"lev";
static NSString * const kGTGameParameterResult          = @"result";
static NSString * const kGTGameParameterMethod          = @"method";

#pragma mark - AD
static NSString * const GTGameEventAdButtonclick        = @"gt_ad_button_click";
static NSString * const GTGameEventAdShow               = @"gt_ad_show";
static NSString * const GTGameEventAdShowEnd            = @"gt_ad_show_end";

static NSString * const kGTGameParameterAdType              = @"ad_type";
static NSString * const kGTGameParameterAdPositionType      = @"ad_position_type";
static NSString * const kGTGameParameterAdPosition          = @"ad_position";

#pragma mark - Level
static NSString * const GTGameEventLevelup              = @"gt_levelup";

static NSString * const kGTGameParameterGetExp          = @"get_exp";
static NSString * const kGTGameParameterAfterLevel      = @"aflev";

#pragma mark - play
static NSString * const GTGameEventStartPlay            = @"gt_start_play";
static NSString * const GTGameEventEndPlay              = @"gt_end_play";

static NSString * const kGTGameParameterEctypeName      = @"ectype_name";
static NSString * const kGTGameParameterDuration        = @"duration";

#pragma mark - coins
static NSString * const GTGameEventGetCoins             = @"gt_get_coins";
static NSString * const GTGameEventCostCoins            = @"gt_cost_coins";

static NSString * const kGTGameParameterCoinType        = @"coin_type";
static NSString * const kGTGameParameterCoinNum         = @"coin_num";

#pragma mark - Purchase
static NSString * const GTGameEventPurchase             = @"purchase";

static NSString * const kGTGameParameterContentId       = @"content_id";
static NSString * const kGTGameParameterContentName     = @"content_name";
static NSString * const kGTGameParameterContentNum      = @"content_num";
static NSString * const kGTGameParameterContentType     = @"content_type";

static NSString * const kGTGameParameterCurrency            = @"currency";
static NSString * const kGTGameParameterCurrencyAmount      = @"currency_amount";
static NSString * const kGTGameParameterIsSuccess           = @"is_success";
static NSString * const kGTGameParameterPaymentChannel      = @"payment_channel";

#pragma mark - InitInfo
static NSString * const GTGameEventGameInitInfo         = @"gt_init_info";

static NSString * const kGTGameParameterCoinLeft        = @"coin_left";


@implementation BDAutoTrack (GameTrack)

- (void)adButtonClickEventWithADType:(NSString *)adType
                        positionType:(NSString *)positionType
                            position:(NSString *)position
                         otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:adType forKey:kGTGameParameterAdType];
    [params setValue:positionType forKey:kGTGameParameterAdPositionType];
    [params setValue:position forKey:kGTGameParameterAdPosition];
    
    [self eventV3:GTGameEventAdButtonclick params:params];
}

- (void)adShowEventWithADType:(NSString *)adType
                 positionType:(NSString *)positionType
                     position:(NSString *)position
                  otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:adType forKey:kGTGameParameterAdType];
    [params setValue:positionType forKey:kGTGameParameterAdPositionType];
    [params setValue:position forKey:kGTGameParameterAdPosition];
    
    [self eventV3:GTGameEventAdShow params:params];
}

- (void)adShowEndEventWithADType:(NSString *)adType
                    positionType:(NSString *)positionType
                        position:(NSString *)position
                          result:(NSString *)result
                     otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:adType forKey:kGTGameParameterAdType];
    [params setValue:positionType forKey:kGTGameParameterAdPositionType];
    [params setValue:position forKey:kGTGameParameterAdPosition];
    [params setValue:result forKey:kGTGameParameterResult];
    
    [self eventV3:GTGameEventAdShowEnd params:params];
}

- (void)levelUpEventWithLevel:(NSInteger)level
                          exp:(NSInteger)exp
                       method:(NSString *)method
                   afterLevel:(NSInteger)afterLevel
                  otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:@(level) forKey:kGTGameParameterLevel];
    [params setValue:@(exp) forKey:kGTGameParameterGetExp];
    [params setValue:method forKey:kGTGameParameterMethod];
    [params setValue:@(afterLevel) forKey:kGTGameParameterAfterLevel];
    
    [self eventV3:GTGameEventLevelup params:params];
}

- (void)startPlayEventWithName:(NSString *)ecTypeName
                   otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:ecTypeName forKey:kGTGameParameterEctypeName];
    [self eventV3:GTGameEventStartPlay params:params];
}

- (void)endPlayEventWithName:(NSString *)ecTypeName
                      result:(NSString *)result
                    duration:(NSInteger)duration
                 otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:ecTypeName forKey:kGTGameParameterEctypeName];
    [params setValue:result forKey:kGTGameParameterResult];
    [params setValue:@(duration) forKey:kGTGameParameterDuration];
    
    [self eventV3:GTGameEventEndPlay params:params];
}

- (void)getCoinsEventWitType:(NSString *)coinType
                      method:(NSString *)method
                  coinNumber:(NSInteger)number
                 otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:coinType forKey:kGTGameParameterCoinType];
    [params setValue:method forKey:kGTGameParameterMethod];
    [params setValue:@(number) forKey:kGTGameParameterCoinNum];
    
    [self eventV3:GTGameEventGetCoins params:params];
}

- (void)costCoinsEventWitType:(NSString *)coinType
                       method:(NSString *)method
                   coinNumber:(NSInteger)number
                  otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:coinType forKey:kGTGameParameterCoinType];
    [params setValue:method forKey:kGTGameParameterMethod];
    [params setValue:@(number) forKey:kGTGameParameterCoinNum];
    
    [self eventV3:GTGameEventCostCoins params:params];
}

- (void)purchaseEventWithContentType:(NSString *)contentType
                         contentName:(NSString *)contentName
                           contentID:(NSString *)contentID
                          contentNum:(NSInteger)contentNum
                             channel:(NSString *)channel
                            currency:(NSString *)currency
                           isSuccess:(NSString *)isSuccess
                      currencyAmount:(NSInteger)currencyAmount
                         otherParams:(nullable NSDictionary *)otherParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:contentType forKey:kGTGameParameterContentType];
    [params setValue:contentName forKey:kGTGameParameterContentName];
    [params setValue:contentID forKey:kGTGameParameterContentId];
    [params setValue:@(contentNum) forKey:kGTGameParameterContentNum];
    
    [params setValue:channel forKey:kGTGameParameterPaymentChannel];
    [params setValue:currency forKey:kGTGameParameterCurrency];
    [params setValue:isSuccess forKey:kGTGameParameterIsSuccess];
    [params setValue:@(currencyAmount) forKey:kGTGameParameterCurrencyAmount];

    [self eventV3:GTGameEventPurchase params:params];
}

- (void)gameInitInfoEventWithLevel:(NSInteger)level
                          coinType:(NSString *)coinType
                          coinLeft:(NSInteger)coinLeft
                       otherParams:(nullable NSDictionary *)otherParams  {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:otherParams copyItems:YES];
    [params setValue:@(level) forKey:kGTGameParameterLevel];
    [params setValue:coinType forKey:kGTGameParameterCoinType];
    [params setValue:@(coinLeft) forKey:kGTGameParameterCoinLeft];

    [self eventV3:GTGameEventGameInitInfo params:params];
}

@end
