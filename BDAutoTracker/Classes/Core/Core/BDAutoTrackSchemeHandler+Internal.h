//
//  BDAutoTrackSchemeHandler+Internal.h
//  RangersAppLog
//
//  Created by bob on 2020/5/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackSchemeHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackInternalHandler;

@interface BDAutoTrackSchemeHandler (Internal)

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDAutoTrackInternalHandler *> *internalHandlers;

- (BOOL)handleInternalURL:(NSURL *)URL appID:(NSString *)appID scene:(id)scene;
- (void)registerInternalHandler:(BDAutoTrackInternalHandler *)handler;
- (void)unregisterInternalHandler:(BDAutoTrackInternalHandler *)handler;

@end

NS_ASSUME_NONNULL_END
