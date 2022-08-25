//
//  BDroneDefines.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#ifndef BDroneDefines_h
#define BDroneDefines_h


#import <Foundation/Foundation.h>

@protocol BDroneTracker

@required
- (NSString *)applicationId;

@end

@protocol BDroneModule

+ (instancetype)moduleWithTracker:(id<BDroneTracker>)tracker;

- (id<BDroneTracker>)tracker;

@end


#endif /* BDroneDefines_h */
