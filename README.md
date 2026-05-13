English | [简体中文](./README.zh-CN.md)

# DataRangers iOS SDK

## Usage

> For more information: [Integration Document](https://www.volcengine.com/docs/6285/65978)

### 1. Initialize the SDK

Initialize SDK in `application:didFinishLaunchingWithOptions:`

```objc

@import RangersAppLog;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:<#your application id#> launchOptions:launchOptions];
    
    config.appName = <# enter your your app name #>;
    config.channel = <# enter your your app channel #>;

    config.abEnable = YES;      //enable A/B test
    
    config.encryptionDelegate = <# Custom encryption definition #> //Provides an implementation of BDAutoTrackEncryptionDelegate encryption protocol
    config.logNeedEncrypt = YES; //enable encryption, YES by default

    config.showDebugLog = YES;  //enable console log, NO by default

    config.serviceVendor = BDAutoTrackServiceVendorPrivate; //Identifies the use of privatized deployment servers

    [BDAutoTrack sharedTrackWithConfig:config];

    //Provides host of privatized deployment servers
    [[BDAutoTrack sharedTrack] setRequestHostBlock:^NSString * _Nullable(BDAutoTrackServiceVendor  _Nonnull vendor, BDAutoTrackRequestURLType requestURLType) {
        return <# your server host #>
    }];
    
    [[BDAutoTrack sharedTrack] startTrack];
    
}

```

### 2. Track event

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

## Security and privacy
This project takes security seriously. 
For vulnerability reporting and supported versions, see [SECURITY.md](SECURITY.md)
