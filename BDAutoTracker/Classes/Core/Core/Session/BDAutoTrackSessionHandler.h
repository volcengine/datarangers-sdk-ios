//
//  BDAutoTrackSessionHandler.h
//  Applog
//
//  Created by bob on 2019/1/18.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDCommonDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackSessionHandler : NSObject

@property (atomic, copy, readonly) NSString *sessionID;
@property (nonatomic, assign) BDAutoTrackLaunchFrom launchFrom;
@property (nonatomic, copy, readonly) NSArray *previousLaunchs;
@property (nonatomic, copy, readonly) NSArray *previousTerminates;

@property (nonatomic) BOOL shouldMarkLaunchedPassively;

+ (instancetype)sharedHandler;

- (BOOL)checkAndStartSession;

- (void)startSessionWithIDChange:(BOOL)change;


- (void)onUUIDChanged;
- (void)createUUIDChangeSession;

- (NSInteger)computeTotalDuration;

@end

NS_ASSUME_NONNULL_END
