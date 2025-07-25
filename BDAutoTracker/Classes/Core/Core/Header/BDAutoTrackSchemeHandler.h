//
//  BDAutoTrackSchemeHandler.h
//  RangersAppLog
//
//  Created by bob on 2019/9/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackSchemeHandler : NSObject<BDAutoTrackSchemeHandler>

+ (instancetype)sharedHandler;

- (BOOL)handleURL:(NSURL *)URL appID:(NSString *)appID scene:(nullable id)scene;

- (void)registerHandler:(id<BDAutoTrackSchemeHandler>)handler;
- (void)unregisterHandler:(id<BDAutoTrackSchemeHandler>)handler;

@end

NS_ASSUME_NONNULL_END
