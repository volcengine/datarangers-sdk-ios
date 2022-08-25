//
//  VEInstallFileStorage.h
//  VEInstall
//
//  Created by KiBen on 2021/9/7.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 存储服务端返回的json
 {
     "bd_did" = UEUYC3NM6F46BQOFAAJ2YOBRTYMUKVKEXPNS22AIT4FRIQ7IATBQ01;
     cd = "a3D0m-2P9OQF5YpZKaRZBO_aUQs6IMgh5YNRMDn-fok10";
     "device_id" = 0;
     "device_token" = AAA2G6W6EZPHWUCQFOEHNTRJN6GSA2WUYT47IIUG2AUGI57ZGHHWG6BBEI22UUC5LD5KBEFLQER4463V76KPTQSMEWUZW6URZWQDZ5D6ICZNY377IL7YKGT3UOUPE;
     "install_id" = 7003959743330600748;
     "install_id_str" = 7003959743330600748;
     "new_user" = 1;
     "server_time" = 1630899610;
     ssid = "d52132ab-c8cf-41e3-820a-0851b7bd98cb";
 }
 */

FOUNDATION_EXTERN BOOL ve_install_file_save(NSString * fileName, NSDictionary * content);
FOUNDATION_EXTERN NSDictionary * ve_install_file_load(NSString *fileName);
FOUNDATION_EXTERN BOOL ve_install_file_delete(NSString *fileName);

NS_ASSUME_NONNULL_END
