//
//  BDAutoTrackEncryptionDelegate.h
//  RangersAppLog
//
//  Created by 朱元清 on 2021/8/9.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDAutoTrackEncryptionDelegate <NSObject>
@required
- (NSData *)encryptData:(NSData *)data error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
