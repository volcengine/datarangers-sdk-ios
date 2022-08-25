//
//  VEInstallDataCompressProvider.h
//  VEInstall
//
//  Created by KiBen on 2021/9/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VEInstallDataCompressProvider <NSObject>

/// 数据压缩
/// @param originalData 原始待压缩数据
/// @return 压缩后的数据
+ (NSData *_Nullable)compressData:(NSData *)originalData;

@end

NS_ASSUME_NONNULL_END
