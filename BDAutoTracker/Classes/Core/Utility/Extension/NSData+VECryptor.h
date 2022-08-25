//
//  NSData+VECryptor.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/6/6.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VEAESKeySize) {
    VEAESKeySizeAES128 = 0x10, /// 对应key的byte是16字节
    VEAESKeySizeAES192 = 0x18, /// 对应key的byte是24字节
    VEAESKeySizeAES256 = 0x20, /// 对应key的byte是32字节
};

@interface NSData (VECryptor)

- (nullable NSData *)veaes_encryptWithKey:(NSString *)key
                                     size:(VEAESKeySize)size
                                       iv:(nullable NSString *)iv;

- (nullable NSData *)veaes_encryptWithKeyData:(NSData *)data
                                         size:(VEAESKeySize)size
                                       ivData:(nullable NSData *)iv;

- (nullable NSData *)veaes_decryptWithKey:(NSString *)key
                                     size:(VEAESKeySize)size
                                       iv:(nullable NSString *)iv;

- (nullable NSData *)veaes_decryptWithKeyData:(NSData *)data
                                         size:(VEAESKeySize)size
                                       ivData:(nullable NSData *)iv;


@end

NS_ASSUME_NONNULL_END
