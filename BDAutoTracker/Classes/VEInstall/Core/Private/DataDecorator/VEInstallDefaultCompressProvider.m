//
//  VEInstallDefaultCompressProvider.m
//  VEInstall
//
//  Created by KiBen on 2021/9/14.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallDefaultCompressProvider.h"
#import "NSData+VEGZip.h"
#import "VEInstallLog.h"

@implementation VEInstallDefaultCompressProvider

+ (NSData *_Nullable)compressData:(NSData *)originalData {
    NSError *error = nil;
    NSData *compressedData = [originalData ve_dataByGZipCompressingWithError:&error];
    if (error) {
        InstallLog(@"压缩数据失败: %@", error);
        return nil;
    }
    return compressedData;
}

@end
