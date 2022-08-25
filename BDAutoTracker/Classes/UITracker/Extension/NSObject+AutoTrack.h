//
//  NSObject+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/28.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (AutoTrack)

@property (nonatomic, assign) BOOL bd_AutoTrackInternalItem;

@end

@interface NSProxy (AutoTrack)

@property (nonatomic, assign) BOOL bd_AutoTrackInternalItem;

@end

NS_ASSUME_NONNULL_END
