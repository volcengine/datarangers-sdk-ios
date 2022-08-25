//
//  BDAutoTrack+Game.m
//  Applog
//
//  Created by bob on 2019/4/10.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrack+Game.h"

#define BDStringForBOOL(value) (value ? @"yes" : @"no")

static NSString * const kBDAutoTrackGameRegisterEvent = @"register";
static NSString * const kBDAutoTrackGameLoginEvent = @"log_in";
static NSString * const kBDAutoTrackGameAccessAccountEvent = @"access_account";
static NSString * const kBDAutoTrackGameQusetEvent = @"quest";
static NSString * const kBDAutoTrackGameUpdateLevelEvent = @"update_level";
static NSString * const kBDAutoTrackGameViewContentEvent = @"view_content";
static NSString * const kBDAutoTrackGameViewAddCartEvent = @"add_cart";
static NSString * const kBDAutoTrackGameViewCheckoutEvent = @"checkout";
static NSString * const kBDAutoTrackGamePurchaseEvent = @"purchase";
static NSString * const kBDAutoTrackGameAccessPaymentChannelEvent = @"access_payment_channel";
static NSString * const kBDAutoTrackGameCreateRoleEvent = @"create_gamerole";
static NSString * const kBDAutoTrackGameAddFavouriteEvent = @"add_to_favourite";

static NSString * const kBDAGameMethod              = @"method";
static NSString * const kBDAGameIsSuccess           = @"is_success";
static NSString * const kBDAGameAccountType         = @"account_type";
static NSString * const kBDAGamePaymentChannel      = @"payment_channel";
static NSString * const kBDAGameRoleID              = @"gamerole_id";

static NSString * const kBDAGameQuestID             = @"quest_id";
static NSString * const kBDAGameQuestType           = @"quest_type";
static NSString * const kBDAGameQuestName           = @"quest_name";
static NSString * const kBDAGameQuestNo             = @"quest_no";

static NSString * const kBDAGameDescription         = @"description";

NSString * const kBDAGameLevel                      = @"level";

static NSString * const kBDAGameContentType         = @"content_type";
static NSString * const kBDAGameContentName         = @"content_name";
static NSString * const kBDAGameContentID           = @"content_id";
static NSString * const kBDAGameContentNum          = @"content_num";
static NSString * const kBDAGameIsVirtualCurrency   = @"is_virtual_currency";
static NSString * const kBDAGameVirtualCurrency     = @"virtual_currency";
static NSString * const kBDAGameCurrency            = @"currency";
static NSString * const kBDAGameCurrencyAmount      = @"currency_amount";



@implementation BDAutoTrack (Game)

- (void)registerEventByMethod:(NSString *)method isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:method forKey:kBDAGameMethod];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameRegisterEvent params:params];
}

- (void)loginEventByMethod:(NSString *)method isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:method forKey:kBDAGameMethod];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameLoginEvent params:params];
}

- (void)accessAccountEventByType:(NSString *)type isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:type forKey:kBDAGameAccountType];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameAccessAccountEvent params:params];
}

- (void)questEventWithQuestID:(NSString *)questID
                    questType:(NSString *)type
                    questName:(NSString *)name
                   questNumer:(NSUInteger)number
                  description:(NSString *)desc
                    isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:6];
    [params setValue:questID forKey:kBDAGameQuestID];
    [params setValue:type forKey:kBDAGameQuestType];
    [params setValue:name forKey:kBDAGameQuestName];
    [params setValue:@(number) forKey:kBDAGameQuestNo];
    [params setValue:desc forKey:kBDAGameDescription];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameQusetEvent params:params];
}

- (void)updateLevelEventWithLevel:(NSUInteger)level {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    [params setValue:@(level) forKey:kBDAGameLevel];

    [self eventV3:kBDAutoTrackGameUpdateLevelEvent params:params];
}

- (void)viewContentEventWithContentType:(NSString *)type
                            contentName:(NSString *)name
                              contentID:(NSString *)contentID {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    [params setValue:type forKey:kBDAGameContentType];
    [params setValue:name forKey:kBDAGameContentName];
    [params setValue:contentID forKey:kBDAGameContentID];

    [self eventV3:kBDAutoTrackGameViewContentEvent params:params];
}

- (void)addCartEventWithContentType:(NSString *)type
                        contentName:(NSString *)name
                          contentID:(NSString *)contentID
                      contentNumber:(NSUInteger)number
                          isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    [params setValue:type forKey:kBDAGameContentType];
    [params setValue:name forKey:kBDAGameContentName];
    [params setValue:contentID forKey:kBDAGameContentID];
    [params setValue:@(number) forKey:kBDAGameContentNum];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameViewAddCartEvent params:params];
}

- (void)checkoutEventWithContentType:(NSString *)type
                         contentName:(NSString *)name
                           contentID:(NSString *)contentID
                       contentNumber:(NSUInteger)number
                   isVirtualCurrency:(BOOL)isVirtualCurrency
                     virtualCurrency:(NSString *)virtualCurrency
                            currency:(NSString *)currency
                     currency_amount:(unsigned long long)amount
                           isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];
    [params setValue:type forKey:kBDAGameContentType];
    [params setValue:name forKey:kBDAGameContentName];
    [params setValue:contentID forKey:kBDAGameContentID];
    [params setValue:@(number) forKey:kBDAGameContentNum];
    [params setValue:BDStringForBOOL(isVirtualCurrency) forKey:kBDAGameIsVirtualCurrency];
    [params setValue:virtualCurrency forKey:kBDAGameVirtualCurrency];
    [params setValue:currency forKey:kBDAGameCurrency];
    [params setValue:@(amount) forKey:kBDAGameCurrencyAmount];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameViewCheckoutEvent params:params];
}

- (void)purchaseEventWithContentType:(NSString *)type
                         contentName:(NSString *)name
                           contentID:(NSString *)contentID
                       contentNumber:(NSUInteger)number
                      paymentChannel:(NSString *)channel
                            currency:(NSString *)currency
                     currency_amount:(unsigned long long)amount
                           isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];
    [params setValue:type forKey:kBDAGameContentType];
    [params setValue:name forKey:kBDAGameContentName];
    [params setValue:contentID forKey:kBDAGameContentID];
    [params setValue:@(number) forKey:kBDAGameContentNum];
    [params setValue:channel forKey:kBDAGamePaymentChannel];
    [params setValue:currency forKey:kBDAGameCurrency];
    [params setValue:@(amount) forKey:kBDAGameCurrencyAmount];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGamePurchaseEvent params:params];
}

- (void)accessPaymentChannelEventByChannel:(NSString *)channel isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:channel forKey:kBDAGamePaymentChannel];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameAccessPaymentChannelEvent params:params];
}

- (void)createGameRoleEventByID:(NSString *)roleID {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    [params setValue:roleID forKey:kBDAGameRoleID];

    [self eventV3:kBDAutoTrackGameCreateRoleEvent params:params];
}

- (void)addToFavouriteEventWithContentType:(NSString *)type
                               contentName:(NSString *)name
                                 contentID:(NSString *)contentID
                             contentNumber:(NSUInteger)number
                                 isSuccess:(BOOL)isSuccess {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];
    [params setValue:type forKey:kBDAGameContentType];
    [params setValue:name forKey:kBDAGameContentName];
    [params setValue:contentID forKey:kBDAGameContentID];
    [params setValue:@(number) forKey:kBDAGameContentNum];
    [params setValue:BDStringForBOOL(isSuccess) forKey:kBDAGameIsSuccess];

    [self eventV3:kBDAutoTrackGameAddFavouriteEvent params:params];
}

@end
