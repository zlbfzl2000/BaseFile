//
//  NSData+ZLExtension.m
//  BaseDemo
//
//  Created by snowlu on 2018/1/22.
//  Copyright © 2018年 LittleShrimp. All rights reserved.
//

#import "NSData+ZLExtension.h"

@implementation NSData (ZLExtension)
- (NSData *)aes256_encrypt:(NSString *)key   //加密
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}


- (NSData *)aes256_decrypt:(NSString *)key   //解密
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        
    }
    free(buffer);
    return nil;
}
- (NSData *)AES128EncryptWithKey:(NSString *)key {
    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}


- (NSData *)AES128DecryptWithKey:(NSString *)key {
    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode, // must be the same pad when encryed
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}
- (NSData *)UTF8Data
{
    //保存结果
    NSMutableData *resData = [[NSMutableData alloc] initWithCapacity:self.length];
    
    //无效编码替代符号(常见 � □ ?)
    NSData *replacement = [@"�" dataUsingEncoding:NSUTF8StringEncoding];
    
    uint64_t index = 0;
    const uint8_t *bytes = self.bytes;
    
    while (index < self.length)
    {
        uint8_t len = 0;
        uint8_t header = bytes[index];
        
        //单字节
        if ((header&0x80) == 0)
        {
            len = 1;
        }
        //2字节(并且不能为C0,C1)
        else if ((header&0xE0) == 0xC0)
        {
            if (header != 0xC0 && header != 0xC1)
            {
                len = 2;
            }
        }
        //3字节
        else if((header&0xF0) == 0xE0)
        {
            len = 3;
        }
        //4字节(并且不能为F5,F6,F7)
        else if ((header&0xF8) == 0xF0)
        {
            if (header != 0xF5 && header != 0xF6 && header != 0xF7)
            {
                len = 4;
            }
        }
        
        //无法识别
        if (len == 0)
        {
            [resData appendData:replacement];
            index++;
            continue;
        }
        
        //检测有效的数据长度(后面还有多少个10xxxxxx这样的字节)
        uint8_t validLen = 1;
        while (validLen < len && index+validLen < self.length)
        {
            if ((bytes[index+validLen] & 0xC0) != 0x80)
                break;
            validLen++;
        }
        
        //有效字节等于编码要求的字节数表示合法,否则不合法
        if (validLen == len)
        {
            [resData appendBytes:bytes+index length:len];
        }else
        {
            [resData appendData:replacement];
        }
        
        //移动下标
        index += validLen;
    }
    
    return resData;
}
@end
