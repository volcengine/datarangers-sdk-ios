//
//  UIViewController+AutoTrack.h
//  Applog
//
//  Created by bob on 2019/1/20.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (TrackInfo)

/*! @abstract 手动设置的PageTitle
 @discussion 如果设置，页面切换的时候会采集
 @discussion 如果设置，该VC里面的View被点击的时候会采集
 */
@property (nonatomic, copy) NSString *bdAutoTrackPageTitle;

/*! @abstract 手动设置的PageID
 @discussion 如果设置，页面切换的时候会采集
 @discussion 如果设置，该VC里面的View被点击的时候会采集
 */
@property (nonatomic, copy) NSString *bdAutoTrackPageID;

/*! @abstract 手动设置的PagePath
 @discussion 如果设置，页面切换的时候会采集
 @discussion 如果设置，该VC里面的View被点击的时候会采集
 */
@property (nonatomic, copy) NSString *bdAutoTrackPagePath;

/*! @abstract 手动设置的extra信息
 @discussion 如果设置，页面切换的时候会采集
 @discussion 如果设置，该VC里面的View被点击的时候会采集
 */
@property (nonatomic, copy) NSDictionary<NSString*, NSString *> *bdAutoTrackExtraInfos;

/*! @abstract 自定义采集属性，相同 key 会覆盖默认采集的 params
 @discussion 如果设置，页面切换的时候会采集
 @discussion 如果设置，该VC里面的View被点击的时候会采集
 */
@property (nonatomic, copy) NSDictionary<NSString*, NSObject *> *bdAutoTrackPageProperties;

@end

NS_ASSUME_NONNULL_END
