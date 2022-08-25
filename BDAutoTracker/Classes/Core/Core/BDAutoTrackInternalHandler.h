//
//  BDAutoTrackInternalHandler.h
//  RangersAppLog
//
//  Created by bob on 2020/5/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackInternalHandler : NSObject

@property (nonatomic, copy) NSString *type;

- (BOOL)handleWithAppID:(NSString *)appID
                qrParam:(NSString *)qrParam
                  scene:(id)scene;

@end

NS_ASSUME_NONNULL_END
