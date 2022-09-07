[English](./README.md) | 简体中文

# 增长分析营销套件 iOS SDK

## 使用

> 更多信息请查看：[集成文档](https://www.volcengine.com/docs/6285/65978)

### 1. 初始化 SDK

在 `application:didFinishLaunchingWithOptions:` 中初始化 SDK。

```objc

@import RangersAppLog;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:<#your application id#> launchOptions:launchOptions];
    
    config.appName = <# enter your your app name #>;
    config.channel = <# enter your your app channel #>;

    config.abEnable = YES;      //开启 ABTesting
    
    config.encryptionDelegate = <# Custom encryption definition #> //由用户提供支持BDAutoTrackEncryptionDelegate协议的加密实现
    config.logNeedEncrypt = YES; //开启报文加密、默认YES

    config.showDebugLog = YES;  //开启命令行日志、默认NO

    config.serviceVendor = BDAutoTrackServiceVendorPrivate; //标识服务路径为客户私有化部署服务器

    [BDAutoTrack sharedTrackWithConfig:config];

    //提供私有化部署的访问域名
    [[BDAutoTrack sharedTrack] setRequestHostBlock:^NSString * _Nullable(BDAutoTrackServiceVendor  _Nonnull vendor, BDAutoTrackRequestURLType requestURLType) {
        return <# your server host #>
    }]; 
    
    [[BDAutoTrack sharedTrack] startTrack];
    
}

```

### 2. 上报事件

```objc

   [[BDAutoTrack sharedTrack] eventV3:<# event code #> params:<# NSDictionary type parameter, should be valid JSONObject #>];
 
```

## License

Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

The DataRangers SDK was developed by Beijing Volcanoengine Technology Ltd. (hereinafter “Volcanoengine”). Any copyright or patent right is owned by and proprietary material of the Volcanoengine.

DataRangers SDK is available under the Volcanoengine and licensed under the commercial license.  Customers can contact service@volcengine.com for commercial licensing options.  Here is also a link to subscription services agreement: https://www.volcengine.com/docs/6285/69647

Without Volcanoengine's prior written permission, any use of DataRangers SDK, in particular any use for commercial purposes, is prohibited. This includes, without limitation, incorporation in a commercial product, use in a commercial service, or production of other artefacts for commercial purposes.

Without Volcanoengine's prior written permission, the DataRangers SDK may not be reproduced, modified and/or made available in any form to any third party.

THE FOLLOWING SETS FORTH ATTRIBUTION NOTICES FOR THIRD PARTY SOFTWARE THAT MAY BE CONTAINED IN PORTIONS OF Volcanoengine.
