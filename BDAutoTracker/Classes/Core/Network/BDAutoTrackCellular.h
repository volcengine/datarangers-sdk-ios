//
//  BDAutoTrackCellular.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/26.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#if TARGET_OS_IOS

#import <Foundation/Foundation.h>
#import "BDAutoTrackEnviroment.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackCellular : NSObject

+ (instancetype)sharedInstance;

- (id)carrier;

- (BDAutoTrackConnectionType)connectionType;

@end


NS_ASSUME_NONNULL_END

#endif
