//
//  BDKeyWindowTracker.h
//  RangersAppLog
//
//  Created by bob on 2019/8/12.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString * const BDDefaultScene;

@interface BDKeyWindowTracker : NSObject

@property (nonatomic, strong, nullable) UIWindow *keyWindow;

+ (instancetype)sharedInstance;

- (void)trackScene:(NSString *)scene keyWindow:(nullable UIWindow *)keyWindow;

- (nullable UIWindow *)keyWindowForScene:(NSString *)scene;

- (void)removeKeyWindowForScene:(NSString *)scene; 

@end

NS_ASSUME_NONNULL_END
