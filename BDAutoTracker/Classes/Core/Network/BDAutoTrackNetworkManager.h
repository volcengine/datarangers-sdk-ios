//
//  BDAutoTrackNetworkManager.h
//  Applog
//
//  Created by bob on 2019/3/4.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackEncryptionDelegate.h"
#import "BDCommonEnumDefine.h"

NS_ASSUME_NONNULL_BEGIN
//typedef void (^BDAutoTrackNetworkFinishBlock)(BDAutoTrackNetworkResponse *networkResponse);
typedef void (^BDAutoTrackNetworkFinishBlock)(NSData *data, NSURLResponse *urlResponse, NSError *error);

typedef void (^BDSyncNetworkFinishBlock)(NSData *data, NSURLResponse *response, NSError *error);

@class BDAutoTrackNetworkManager;
FOUNDATION_EXTERN void bd_buildBodyData(NSMutableURLRequest *request, NSDictionary *parameters, BDAutoTrackNetworkManager *networkManager);

@class BDAutoTrackNetworkManager;
FOUNDATION_EXTERN void bd_buildBodyData_without_encryptor(NSMutableURLRequest *request, NSDictionary *parameters, BDAutoTrackNetworkManager *networkManager);

FOUNDATION_EXTERN void bd_network_asyncRequestForURL(NSString *requestURL,
                                                     NSString *method,
                                                     NSTimeInterval timeout,
                                                     NSDictionary *headerField,
                                                     NSDictionary *parameters,
                                                     BDAutoTrackNetworkManager *networkManager,
                                                     BDAutoTrackNetworkFinishBlock _Nullable callback);

FOUNDATION_EXTERN NSDictionary * bd_network_syncRequestForURL(NSString *requestURL,
                                                              NSString *method,
                                                              NSDictionary *headerField,
                                                              NSDictionary *parameters,
                                                              BDAutoTrackNetworkManager *networkManager);


@class BDAutoTrack;

@interface BDAutoTrackNetworkEncryptor : NSObject

@property (nonatomic, assign) BOOL encryption;

@property (nonatomic, assign) BDAutoTrackEncryptionType encryptionType;

@property (nonatomic, nullable) id<BDAutoTrackEncryptionDelegate> customDelegate;

- (void)encryptRequest:(NSMutableURLRequest *)request tracker:(BDAutoTrack *)tracker;

- (NSMutableDictionary *)encryptParameters:(NSMutableDictionary *)parameters allowedKeys:(NSArray *)allowedKeys;

- (NSString *)encryptUrl:(NSString *)url allowedKeys:(NSArray *)allowedKeys;

- (void)addIV:(NSDictionary *)dict;

- (NSDictionary *)decryptResponse:(NSData *)data;

- (NSDictionary *)parseResponse:(NSData *)data;

- (NSString *)contentTypeHeader;

@end

@interface BDAutoTrackNetworkRequestConfig : NSObject

@property (nonatomic, assign) NSUInteger retry;

@property (nonatomic, assign) NSTimeInterval timeout;

@property (nonatomic, assign) BOOL requireDeviceRegister;

@end


@interface BDAutoTrackNetworkManager : NSObject

@property (nonatomic, weak) BDAutoTrack *tracker;

@property (nonatomic, strong) BDAutoTrackNetworkEncryptor* encryptor;

+ (instancetype)managerWithTracker:(BDAutoTrack *)tracker;

- (void)sync:(BDAutoTrackRequestURLType)type
      method:(NSString *)method
      header:(nullable NSDictionary *)header
   parameter:(nullable NSDictionary *)parameter
      config:(BDAutoTrackNetworkRequestConfig *)config
  completion:(BOOL (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

    
@end


NS_ASSUME_NONNULL_END
