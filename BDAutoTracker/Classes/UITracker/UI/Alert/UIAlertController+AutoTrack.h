//
//  UIAlertController+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/24.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (AutoTrack)

- (NSDictionary *)bd_pageTrackInfo;

@end

NS_ASSUME_NONNULL_END
