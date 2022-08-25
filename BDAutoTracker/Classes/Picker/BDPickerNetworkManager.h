//
//  BDPickerNetworkManager.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonEnumDefine.h"
/// 网络请求

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPickerNetworkFinishBlock)(NSError * _Nullable error, id  _Nullable jsonObj);

FOUNDATION_EXTERN NSString *_Nullable bd_picker_responseMessage(NSDictionary *response);


NS_ASSUME_NONNULL_END
