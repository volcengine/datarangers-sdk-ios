//
//  BDAutoTrackMMap.h
//  RangersAppLog
//
//  Created by 朱元清 on 2020/12/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 析构时自动munmap
@interface BDAutoTrackMMap : NSObject

@property (nonatomic, assign, readonly, nullable) void *memory;
@property (nonatomic, assign, readonly) size_t size;

+ (instancetype)new __attribute__((unavailable()));
- (instancetype)init __attribute__((unavailable()));
- (instancetype)initWithPath:(NSString *)path;

/// 执行mmap
- (void *)mmapWithSize:(size_t)mapSize;

/// 执行munmap
- (void)munmap;

- (BOOL)isMapped;

/// 先munmap，再删除MMAP文件
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
