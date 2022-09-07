![logo](https://portal.volccdn.com/obj/volcfe/logo/appbar_logo_dark.2.svg)
<br><br>

## 增长分析DataFinder
一站式用户分析与运营平台，为企业提供数字化消费者行为分析洞见，优化数字化触点、用户体验，支撑精细化用户运营，发现业务的关键增长点，提升企业效益

## 集成
请参考火山引擎-增长分析 [iOS SDK 集成](https://www.volcengine.com/docs/6285/65978)。

## 使用
```objc

@import RangersAppLog;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    BDAutoTrackConfig *config = [BDAutoTrackConfig configWithAppID:<#your application id#> launchOptions:launchOptions];
    
    [BDAutoTrack sharedTrackWithConfig:config];
    
    [BDAutoTrack startTrack];
    
}

```

## 感谢

- [FBMD](https://github.com/ccgus/fmdb) 
- [Godzippa](https://github.com/mattt/Godzippa) 

## License

Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.

The DataRangers SDK was developed by Beijing Volcanoengine Technology Ltd. (hereinafter “Volcanoengine”). Any copyright or patent right is owned by and proprietary material of the Volcanoengine.

DataRangers SDK is available under the Volcanoengine and licensed under the commercial license.  Customers can contact service@volcengine.com for commercial licensing options.  Here is also a link to subscription services agreement: https://www.volcengine.com/docs/6285/69647

Without Volcanoengine's prior written permission, any use of DataRangers SDK, in particular any use for commercial purposes, is prohibited. This includes, without limitation, incorporation in a commercial product, use in a commercial service, or production of other artefacts for commercial purposes.

Without Volcanoengine's prior written permission, the DataRangers SDK may not be reproduced, modified and/or made available in any form to any third party.

THE FOLLOWING SETS FORTH ATTRIBUTION NOTICES FOR THIRD PARTY SOFTWARE THAT MAY BE CONTAINED IN PORTIONS OF Volcanoengine.
