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

static BOOL bdtracker_fallocate(int fd, size_t length) {
    fstore_t store = {F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, length};
    int ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) {
        store.fst_flags = F_ALLOCATEALL;
        ret = fcntl(fd, F_PREALLOCATE, &store);
        
        if (ret != 0) return NO;
    }
    
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

- (void)destroy {
    [self munmap];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.filePath]) {
        [NSFileManager.defaultManager removeItemAtPath:self.filePath error:nil];
    }
}
@end
