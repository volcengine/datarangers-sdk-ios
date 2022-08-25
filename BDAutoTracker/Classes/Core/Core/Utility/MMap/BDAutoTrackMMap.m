//
//  BDAutoTrackMMap.m
//  RangersAppLog
//
//  Created by 朱元清 on 2020/12/29.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackMMap.h"
#import <sys/stat.h>
#import <sys/mman.h>
#import <mach/mach.h>

@interface BDAutoTrackMMap ()

@property (nonatomic, assign) void *memory;
@property (nonatomic, assign) size_t size;
@property (nonatomic, copy) NSString *filePath;

@end

/// Try allocate continous file space.
/// If failed(maybe disk is too fragmented), allocate non-continuous.
/// @param fd : file to operate on
/// @param length : the length to which the file is truncated (or extended) to.
/// @return YES if the file is truncated (or extended) to length bytes successfully, else NO.
static BOOL bdtracker_fallocate(int fd, size_t length) {
    fstore_t store = {F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, length};
    // Try to get a continous chunk of disk space
    int ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) {
        // OK, perhaps we are too fragmented, allocate non-continuous
        store.fst_flags = F_ALLOCATEALL;
        ret = fcntl(fd, F_PREALLOCATE, &store);
        
        if (ret != 0) return NO;
    }
    
    /*
     int
     ftruncate(int fildes, off_t length);
     
     int
     truncate(const char *path, off_t length);
     
     DESCRIPTION
          ftruncate() and truncate() cause the file named by path, or referenced by fildes, to be truncated (or extended) to length bytes
          in size. If the file size exceeds length, any extra data is discarded. If the file size is smaller than length, the file is
          extended and filled with zeros to the indicated length.  The ftruncate() form requires the file to be open for writing.

          Note: ftruncate() and truncate() do not modify the current file offset for any open file descriptions associated with the file.
     */
    return ftruncate(fd, length) == 0;
}


@implementation BDAutoTrackMMap {
    int fd;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        fd = 0;
        self.memory = NULL;
        self.filePath = path;
    }
    
    return self;
}

/// 执行mmap
/// @param mapSize mmap的大小，未对齐的将自动对齐到内存页。
/// @return mmap返回的内存地址
- (void *)mmapWithSize:(size_t)mapSize {
    if ([self isMapped]) {
        return NULL;
    }
    
    NSString *path = self.filePath;
    if (![path isKindOfClass:NSString.class]) {
        return NULL;
    }
    
    int fd = open([path UTF8String], O_RDWR | O_CREAT, S_IRUSR + S_IWUSR);
    if (fd < 0) {
        return NULL;
    }
    
    struct stat st = {0};
    if (fstat(fd, &st) == -1) {
        close(fd);
        return NULL;
    }
    
    size_t size = round_page(mapSize);
    if (!bdtracker_fallocate(fd, size)) {
        close(fd);
        return NULL;
    }
    
    void *memory = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    if (!memory || memory == MAP_FAILED) {
        return NULL;
    }
    
    self.size = size;
    self.memory = memory;
    return memory;
}

- (void)munmap {
    if (![self isMapped]) {
        return;
    }
    munmap(self.memory, self.size);
    self.memory = NULL;
    self.size = 0;
}

- (void)dealloc {
    [self munmap];
}
#pragma mark -
- (BOOL)isMapped {
    return self.memory != NULL;
}

/// 目前没有caller
- (void)destroy {
    [self munmap];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.filePath]) {
        [NSFileManager.defaultManager removeItemAtPath:self.filePath error:nil];
    }
}
@end
