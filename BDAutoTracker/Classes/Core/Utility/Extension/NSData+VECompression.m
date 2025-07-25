//
//  NSData+VECompression.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSData+VECompression.h"
#import <zlib.h>

static const int vetrackerChunkSize = 1024;
static const int vetrackerDefaultMemoryLevel = 8;
static const int vetrackerDefaultWindowBits = 15;
static const int vetrackerDefaultWindowBitsWithGZipHeader = 16 + vetrackerDefaultWindowBits;
static NSString * const GodzippaZlibErrorDomain = @"com.godzippa.zlib.error";

@implementation NSData (VECompression)

- (NSData *)vecompress_gzip:(NSError **)error
{
    return [self vecompress_dataByGZipCompressingAtLevel:Z_DEFAULT_COMPRESSION
                                      windowSize:vetrackerDefaultWindowBitsWithGZipHeader
                                     memoryLevel:vetrackerDefaultMemoryLevel
                                        strategy:Z_DEFAULT_STRATEGY
                                           error:error];
}

- (NSData *)vecompress_dataByGZipCompressingAtLevel:(int)level
                                  windowSize:(int)windowBits
                                 memoryLevel:(int)memLevel
                                    strategy:(int)strategy
                                       error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }

    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));

    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.next_in = (Bytef *)[self bytes];
    zStream.avail_in = (unsigned int)[self length];
    zStream.total_out = 0;

    OSStatus status;
    if ((status = deflateInit2(&zStream, level, Z_DEFLATED, windowBits, memLevel, strategy)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed deflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain
                                                code:status
                                            userInfo:userInfo];
        }

        return nil;
    }

    NSMutableData *compressedData = [NSMutableData dataWithLength:vetrackerChunkSize];

    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [compressedData length])) {
            [compressedData increaseLengthBy:vetrackerChunkSize];
        }

        zStream.next_out = (Bytef*)[compressedData mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([compressedData length] - zStream.total_out);

        status = deflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));

    deflateEnd(&zStream);

    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error deflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain
                                                code:status
                                            userInfo:userInfo];
        }

        return nil;
    }

    [compressedData setLength:zStream.total_out];

    return compressedData;
}

- (NSData *)vecompress_ungzip:(NSError **)error
{
    return [self vecompress_dataByGZipDecompressingDataWithWindowSize:vetrackerDefaultWindowBitsWithGZipHeader
                                                         error:error];
}


- (NSData *)vecompress_dataByGZipDecompressingDataWithWindowSize:(int)windowBits
                                                    error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }

    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));

    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.avail_in = (unsigned int)[self length];
    zStream.next_in = (Byte *)[self bytes];

    OSStatus status;
    if ((status = inflateInit2(&zStream, windowBits)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed inflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain code:status userInfo:userInfo];
        }

        return nil;
    }

    const NSUInteger estimatedLength = (NSUInteger)((double)[self length] * 1.5);
    size_t bufferLength = sizeof(unsigned char) * estimatedLength;
    unsigned char *buffer = malloc(bufferLength);
    if (buffer == NULL) {
        return nil;
    }
    
    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == bufferLength)) {
            if (bufferLength > estimatedLength * 800) {
                free(buffer);
                return nil;
            }
            bufferLength += estimatedLength;
            unsigned char *buffer_bak = buffer;
            buffer = realloc(buffer, bufferLength);
            if (!buffer) {
                free(buffer_bak);
                return nil;
            }
        }

        zStream.next_out = (Bytef*)buffer + zStream.total_out;
        zStream.avail_out = (unsigned int)(bufferLength - zStream.total_out);

        status = inflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));

    inflateEnd(&zStream);

    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error inflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain code:status userInfo:userInfo];
        }

        return nil;
    }
    
    bufferLength = zStream.total_out;
    unsigned char *buffer_bak = buffer;
    buffer = realloc(buffer, bufferLength);
    if (!buffer) {
        free(buffer_bak);
        return nil;
    }
    
    NSMutableData *decompressedData = [[NSMutableData alloc] initWithBytesNoCopy:buffer length:bufferLength];
    return decompressedData;
}

- (BOOL)vecompress_isGzipData
{
    if (self.length < 3) {
        return NO;
    }
    NSData *subdata = [self subdataWithRange:NSMakeRange(0, 3)];
    const Byte *bytes = (const Byte *)subdata.bytes;
    return bytes[0] == 0x1f && bytes[1] == 0x8b && bytes[2] == 0x08;
}

@end
