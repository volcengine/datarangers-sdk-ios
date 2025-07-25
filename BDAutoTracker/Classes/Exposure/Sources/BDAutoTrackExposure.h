//
//  BDAutoTrackExposure.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/31.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack.h"
#import "BDAutoTrackConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDAutoTrackExposureTriggerType) {
    BDAutoTrackExposureTriggerTypeExposureOnce          = 0,
    BDAutoTrackExposureTriggerTypeLifecycleShowNew      = 3,
    BDAutoTrackExposureTriggerTypeResumeFromPage        = 6,
    BDAutoTrackExposureTriggerTypeResumeFromBack        = 7,
};

typedef BOOL (^BDAutoTrackExposureBlock)(id view, BDAutoTrackExposureTriggerType type, NSString *eventName, NSDictionary *properties);

@interface BDViewExposureConfig : NSObject

+ (instancetype)defaultConfig;

- (instancetype)enableVisualDiagnosis:(BOOL)enable;

- (instancetype)areaRatio:(CGFloat)radio;

- (instancetype)stayTriggerTime:(NSInteger)timestamp;

- (instancetype)exposureBlock:(nullable BDAutoTrackExposureBlock)block;

@end


@interface BDAutoTrackConfig (BDTViewExposure)

@property (nonatomic) BOOL exposureEnabled;

@property (nonatomic) BDViewExposureConfig *exposureConfig;

@end




@interface BDViewExposureData : NSObject

+ (instancetype)event:(nullable NSString *)event
           properties:(nullable NSDictionary *)properties
               config:(nullable BDViewExposureConfig *)config;

@property (nonatomic, copy, nullable) NSString *eventName;

@property (nonatomic, copy, nullable) NSDictionary  *properties;

@property (nonatomic, strong, nullable) BDViewExposureConfig *config;

@end



@interface BDAutoTrack (BDTViewExposure)

- (void)observeViewExposure:(id)view
                   withData:(nullable BDViewExposureData *)data;

- (void)disposeViewExposure:(id)view;

@end

NS_ASSUME_NONNULL_END
