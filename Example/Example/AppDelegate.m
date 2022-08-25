//
//  AppDelegate.m
//  Example
//
//  Created by SoulDiver on 2022/6/7.
//

#import "AppDelegate.h"
@import RangersAppLog;




@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    BDAutoTrackConfig *config =[BDAutoTrackConfig configWithAppID:@"#YOUR_APP_ID#" launchOptions:launchOptions];
    config.appName = @"applog_oc_demo";
    
    config.showDebugLog = YES;  //开启命令行日志
    config.logNeedEncrypt = NO; //关闭加密
    
    //config settings

    config.serviceVendor = BDAutoTrackServiceVendorPrivate;
    
    
    //[BDAutoTrack sharedTrack] init
    [BDAutoTrack sharedTrackWithConfig:config];
    
    [BDAutoTrack setRequestHostBlock:^NSString * _Nullable(BDAutoTrackServiceVendor  _Nonnull vendor, BDAutoTrackRequestURLType requestURLType) {
        return @"#YOUR_HOST#";
    }];
    
    //[BDAutoTrack sharedTrack] start Track
    
    [BDAutoTrack startTrack];
    
    // set event handler
    [[BDAutoTrack sharedTrack] setEventHandler:^BDAutoTrackEventPolicy(BDAutoTrackDataType type, NSString * _Nonnull event, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
        
        if ([event isEqualToString:@"fisrt_event"]) {
            [properties setValue:@"set_in_handler" forKey:@"extra"];
        }
        return BDAutoTrackEventPolicyAccept;
        
    } forTypes:BDAutoTrackDataTypeAll];

    
    
    //
    
    return YES;
}





#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
