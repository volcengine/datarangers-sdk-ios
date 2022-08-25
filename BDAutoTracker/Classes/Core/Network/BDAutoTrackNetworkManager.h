//
//  BDAutoTrackNetworkManager.h
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackEncryptionDelegate.h"
//#import "BDAutoTrackNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN
// 异步网络请求回调类型
//typedef void (^BDAutoTrackNetworkFinishBlock)(BDAutoTrackNetworkResponse *networkResponse);
typedef void (^BDAutoTrackNetworkFinishBlock)(NSData *data, NSURLResponse *urlResponse, NSError *error);

// 同步网络请求回调类型
typedef void (^BDSyncNetworkFinishBlock)(NSData *data, NSURLResponse *response, NSError *error);

FOUNDATION_EXTERN void bd_buildBodyData(NSMutableURLRequest *request, NSDictionary *parameters, BOOL needEncrypt, BOOL needCompress, id<BDAutoTrackEncryptionDelegate> _Nullable encryptionDelegate);

/// 提供基础的网络请求封装
FOUNDATION_EXTERN void bd_network_asyncRequestForURL(NSString *requestURL,
                                                     NSString *method,
                                                     NSDictionary *headerField,
                                                     BOOL needEncrypt,
                                                     BOOL needCompress,
                                                     NSDictionary *parameters,
                                                     BDAutoTrackNetworkFinishBlock _Nullable callback,
                                                     id<BDAutoTrackEncryptionDelegate> _Nullable encryptionDelegate);

FOUNDATION_EXTERN NSDictionary * bd_network_syncRequestForURL(NSString *requestURL,
                                                              NSString *method,
                                                              NSDictionary *headerField,
                                                              BOOL needEncrypt,
                                                              NSDictionary *parameters,
                                                              id<BDAutoTrackEncryptionDelegate> _Nullable encryptionDelegate);

NS_ASSUME_NONNULL_END
