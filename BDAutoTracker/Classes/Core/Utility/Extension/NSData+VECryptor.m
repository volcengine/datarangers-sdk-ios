//
//  NSData+VECryptor.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/6/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSData+VECryptor.h"
#import <CommonCrypto/CommonCryptor.h>

static size_t veaes_keyLength(VEAESKeySize keySize) {
    size_t keyLength = kCCKeySizeAES256;
    switch (keySize) {
        case VEAESKeySizeAES256:
            keyLength = kCCKeySizeAES256;
            break;
        case VEAESKeySizeAES192:
            keyLength = kCCKeySizeAES192;
            break;
        case VEAESKeySizeAES128:
            keyLength = kCCKeySizeAES128;
            break;
    }

    return keyLength;
}


@implementation NSData (VECryptor)

- (nullable NSData *)veaes_encryptWithKey:(NSString *)key
                                     size:(VEAESKeySize)size
                                       iv:(nullable NSString *)iv
{
    if (key.length < 1) {
        return nil;
    }
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    return [self veaes_encryptWithKeyData:keyData size:size ivData:ivData];
}

- (nullable NSData *)veaes_encryptWithKeyData:(NSData *)keyData
                                         size:(VEAESKeySize)size
                                       ivData:(nullable NSData *)ivData
{
    if (keyData.length < 1) {
        return nil;
    }

    size_t keyLength = veaes_keyLength(size);
    /// key
    uint8_t cKey[keyLength];
    bzero(cKey, keyLength);
    [keyData getBytes:cKey length:keyLength];
    
    
    CCOptions option = 0;
    /// IV
    uint8_t cIv[kCCBlockSizeAES128];
    bzero(cIv, kCCBlockSizeAES128);
    if (ivData.length > 0) {
        [ivData getBytes:cIv length:kCCBlockSizeAES128];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }
     /// buffer
    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(sizeof(uint8_t) * bufferSize);
    
    if (buffer == NULL) {
        return nil;
    }
    
    size_t encryptedSize = 0;
    /// Encrypt
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, option,
                                          cKey, keyLength, cIv,
                                          [self bytes], [self length],
                                          buffer, bufferSize, &encryptedSize);

    NSData *result = nil;
    if (cryptStatus == kCCSuccess && encryptedSize > 0) {
        result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
    } else {
        free(buffer);
    }

    return result;
}

- (nullable NSData *)veaes_decryptWithKey:(NSString *)key
                                     size:(VEAESKeySize)size
                                       iv:(nullable NSString *)iv
{
    if (key.length < 1) {
        return nil;
    }
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self veaes_decryptWithKeyData:keyData size:size ivData:ivData];

}

- (nullable NSData *)veaes_decryptWithKeyData:(NSData *)keyData
                                         size:(VEAESKeySize)size
                                       ivData:(nullable NSData *)ivData
{
    if (keyData.length < 1) {
        return nil;
    }
    
    size_t keyLength = veaes_keyLength(size);
    uint8_t cKey[keyLength];
    bzero(cKey, keyLength);
    [keyData getBytes:cKey length:keyLength];

    uint8_t cIv[kCCBlockSizeAES128];
    bzero(cIv, kCCBlockSizeAES128);
    CCOptions option = 0;
    if (ivData.length > 0) {
        [ivData getBytes:cIv length:kCCBlockSizeAES128];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }

    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    void *buffer = malloc(sizeof(uint8_t) * bufferSize);

    if (buffer == NULL) {
        return nil;
    }
    
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES, option,
                                          cKey, keyLength, cIv,
                                          [self bytes], [self length],
                                          buffer, bufferSize, &decryptedSize);

    NSData *result = nil;
    if (cryptStatus == kCCSuccess && decryptedSize > 0) {
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    } else {
        free(buffer);
    }

    return result;
}

@end
