//
//  VEInstallFileStorage.m
//  VEInstall
//
//  Created by KiBen on 2021/9/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "VEInstallFileStorage.h"

#pragma mark - Path
static NSString *ve_install_sandBoxDocumentsPath() {
    
    static NSString *documentsPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [dirs objectAtIndex:0];
    });
    return documentsPath;
}

static NSString *ve_install_document_path() {
    
    static dispatch_once_t onceToken;
    static NSString *documentPath = nil;
    dispatch_once(&onceToken, ^{
        
        NSString *document = ve_install_sandBoxDocumentsPath();
        documentPath = [document stringByAppendingPathComponent:@".VEInstall_document"];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:documentPath isDirectory:&isDir]) {
            if (!isDir) {
                [fm removeItemAtPath:documentPath error:nil];
                [fm createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        } else {
            [fm createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSURL *url = [NSURL fileURLWithPath:documentPath];
        [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    });

    return documentPath;
}

BOOL ve_install_file_save(NSString *fileName, NSDictionary *content) {
    
    if (!content) return false;
    
    if (!fileName || fileName.length == 0) return false;
    
    NSString *filePath = [ve_install_document_path() stringByAppendingPathComponent:fileName];
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingFragmentsAllowed error:nil];
    NSData *base64Data = [contentData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return [base64Data writeToFile:filePath atomically:YES];
}

NSDictionary * ve_install_file_load(NSString *fileName) {
    
    if (!fileName || fileName.length == 0) return nil;
    
    NSString *filePath = [ve_install_document_path() stringByAppendingPathComponent:fileName];
    NSData *base64Data = [[NSData alloc] initWithContentsOfFile:filePath];
    if (!base64Data) {
        return nil;
    }
    NSData *contentData = [[NSData alloc] initWithBase64EncodedData:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!contentData) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:contentData options:NSJSONReadingAllowFragments error:nil];
}

BOOL ve_install_file_delete(NSString *fileName) {
    
    if (!fileName || fileName.length == 0) return false;
    
    NSString *filePath = [ve_install_document_path() stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    return YES;
}


