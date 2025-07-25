//
//  BDAutoTrackScriptMessageHandler.m
//  RangersAppLog
//
//  Created by 朱元清 on 2021/2/23.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDAutoTrackScriptMessageHandler.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrack+Private.h"

typedef NSString BridgedMethod NS_TYPED_ENUM;
static BridgedMethod *BridgedMethod_hasStarted       = @"hasStarted";
static BridgedMethod *BridgedMethod_getDeviceId      = @"getDeviceId";
static BridgedMethod *BridgedMethod_getIid           = @"getIid";
static BridgedMethod *BridgedMethod_getSsid          = @"getSsid";
static BridgedMethod *BridgedMethod_onEventV3        = @"onEventV3";
static BridgedMethod *BridgedMethod_getUserUniqueId  = @"getUserUniqueId";
static BridgedMethod *BridgedMethod_setUserUniqueId  = @"setUserUniqueId";
static BridgedMethod *BridgedMethod_setUserUniqueIdWithType  = @"setUserUniqueIdWithType";
static BridgedMethod *BridgedMethod_profileSet       = @"profileSet";
static BridgedMethod *BridgedMethod_profileSetOnce   = @"profileSetOnce";
static BridgedMethod *BridgedMethod_profileUnset     = @"profileUnset";
static BridgedMethod *BridgedMethod_profileIncrement = @"profileIncrement";
static BridgedMethod *BridgedMethod_profileAppend    = @"profileAppend";
static BridgedMethod *BridgedMethod_addHeaderInfo    = @"addHeaderInfo";
static BridgedMethod *BridgedMethod_removeHeaderInfo = @"removeHeaderInfo";
static BridgedMethod *BridgedMethod_getABTestConfigValueForKey  = @"getABTestConfigValueForKey";
static BridgedMethod *BridgedMethod_getAbSdkVersion  = @"getAbSdkVersion";
static BridgedMethod *BridgedMethod_setNativeAppId   = @"setNativeAppId";
static BridgedMethod *BridgedMethod_setExternalABVersions = @"setExternalAbVersion";
static BridgedMethod *BridgedMethod_getAllAbTestConfigs   = @"getAllAbTestConfigs";

@interface BDAutoTrackScriptMessageHandler ()

@property (nonatomic, strong) NSString *boundAppID;
@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackScriptMessageHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        // pass
    }
    return self;
}

- (BDAutoTrack *)associatedTrack {
    if (_boundAppID) {
        _associatedTrack = [BDAutoTrack trackWithAppID:_boundAppID];
    } else {
        _associatedTrack = [BDAutoTrack sharedTrack];
    }
    return _associatedTrack;
}

#pragma mark - Delegate: WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *msgName = message.name;
    NSDictionary *msgBody;
    WKWebView *msgWebView = message.webView;
    if ([msgName isEqualToString:rangersapplog_script_message_handler_name] && [(msgBody = message.body) isKindOfClass:[NSDictionary class]]) {
        @try {
            BridgedMethod *method = msgBody[@"method"];
            if ([method isKindOfClass:NSNull.class]) {
                method = nil;
            }
            NSArray *methodParams = msgBody[@"params"];
            if ([methodParams isKindOfClass:NSNull.class]) {
                methodParams = nil;
            }
            NSString *JSCallbackID = msgBody[@"callback_id"];
            if ([JSCallbackID isKindOfClass:NSNull.class]) {
                JSCallbackID = nil;
            }
#if DEBUG
            RL_DEBUG(self.associatedTrack,@"Bridged", @"BridgedMethod method: %@", method);
            RL_DEBUG(self.associatedTrack,@"Bridged", @"BridgedMethod params: %@", methodParams);
#endif
            if ([method isKindOfClass:NSString.class] &&
                [methodParams isKindOfClass:NSArray.class] &&
                (JSCallbackID == nil || [JSCallbackID isKindOfClass:NSString.class])) {
                if ([method isEqualToString:BridgedMethod_hasStarted]) {
                    BOOL hasStarted = [self.associatedTrack started];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnNumber:@(hasStarted)];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
#ifdef DEBUG
                        NSLog(@"[yq-debug]执行JS返回, err: %@", error);
#endif
                    }];
                }
                
                else if ([method isEqualToString:BridgedMethod_getDeviceId]) {
                    NSString *deviceID = [self.associatedTrack rangersDeviceID];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:deviceID];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
#ifdef DEBUG
                        NSLog(@"[yq-debug]执行JS返回, err: %@", error);
#endif
                    }];
                }
                else if ([method isEqualToString:BridgedMethod_getIid]) {
                    NSString *installID = [self.associatedTrack installID];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:installID];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
#ifdef DEBUG
                        NSLog(@"[yq-debug]执行JS返回, err: %@", error);
#endif
                    }];
                }
                else if ([method isEqualToString:BridgedMethod_getSsid]) {
                    NSString *ssID = [self.associatedTrack ssID];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:ssID];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
#ifdef DEBUG
                        NSLog(@"[yq-debug]执行JS返回, err: %@", error);
#endif
                    }];
                }
                
                else if ([method isEqualToString:BridgedMethod_onEventV3]) {
                    NSString *event = [methodParams objectAtIndex:0];
                    NSString *paramsJSON = [methodParams objectAtIndex:1];
                    NSDictionary *params = bd_JSONValueForString(paramsJSON);
                    [self.associatedTrack eventV3:event params:params];
                }
                
                else if ([method isEqualToString:BridgedMethod_getUserUniqueId]) {
                    NSString *userUniqueID = [self.associatedTrack userUniqueID];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:userUniqueID];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
#ifdef DEBUG
                        NSLog(@"[yq-debug]执行JS返回, err: %@", error);
#endif
                    }];
                }
                else if ([method isEqualToString:BridgedMethod_setUserUniqueId]) {
                    if ([[self.associatedTrack config] useBridgeUpdateUUIDEnabled]) {
                        NSString *newUserUniqueID = [methodParams objectAtIndex:0];
                        [self.associatedTrack setCurrentUserUniqueID:newUserUniqueID];
                    }
                }
                
                else if ([method isEqualToString:BridgedMethod_setUserUniqueIdWithType] && methodParams.count == 2) {
                    if ([[self.associatedTrack config] useBridgeUpdateUUIDEnabled]) {
                        NSString *newUserUniqueID = [methodParams objectAtIndex:0];
                        NSString *newUserUniqueIDType = [methodParams objectAtIndex:1];
                        [self.associatedTrack setCurrentUserUniqueID:newUserUniqueID withType:newUserUniqueIDType];
                    }
                }
                
                else if ([method isEqualToString:BridgedMethod_profileSet]) {
                    NSString *json = [methodParams objectAtIndex:0];
                    NSDictionary *jsonObject = bd_JSONValueForString(json);
                    if ([jsonObject isKindOfClass:NSDictionary.class]) {
                        [self.associatedTrack profileSet:jsonObject];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_profileSetOnce]) {
                    NSString *json = [methodParams objectAtIndex:0];
                    NSDictionary *jsonObject = bd_JSONValueForString(json);
                    if ([jsonObject isKindOfClass:NSDictionary.class]) {
                        [self.associatedTrack profileSetOnce:jsonObject];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_profileUnset]) {
                    NSString *unsetKey = [methodParams objectAtIndex:0];
                    if ([method isKindOfClass:NSString.class]) {
                        [self.associatedTrack profileUnset:unsetKey];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_profileIncrement]) {
                    NSString *json = [methodParams objectAtIndex:0];
                    NSDictionary *jsonObject = bd_JSONValueForString(json);
                    if ([jsonObject isKindOfClass:NSDictionary.class]) {
                        [self.associatedTrack profileIncrement:jsonObject];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_profileAppend]) {
                    NSString *json = [methodParams objectAtIndex:0];
                    NSDictionary *jsonObject = bd_JSONValueForString(json);
                    if ([jsonObject isKindOfClass:NSDictionary.class]) {
                        [self.associatedTrack profileAppend:jsonObject];
                    }
                }
                
                else if ([method isEqualToString:BridgedMethod_addHeaderInfo]) {
                    NSString *key = [methodParams objectAtIndex:0];
                    id value = [methodParams objectAtIndex:1];
                    if ([key isKindOfClass:NSString.class]) {
                        [self.associatedTrack setCustomHeaderValue:value forKey:key];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_removeHeaderInfo]) {
                    NSString *key = [methodParams objectAtIndex:0];
                    if ([key isKindOfClass:NSString.class]) {
                        [self.associatedTrack removeCustomHeaderValueForKey:key];
                    }
                }
                
                else if ([method isEqualToString:BridgedMethod_getABTestConfigValueForKey]) {
                    NSString *key = [methodParams objectAtIndex:0];
                    NSString *defaultValue = [methodParams objectAtIndex:1];
                    NSString *value;
                    if ([key isKindOfClass:NSString.class] && [defaultValue isKindOfClass:NSString.class]) {
                        value = [self.associatedTrack ABTestConfigValueForKey:key defaultValue:defaultValue];
                    }
                    if ([value isKindOfClass:NSString.class]) {
                        NSString *js = [self JSWithCallbackID:JSCallbackID returnString:value];
                        [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
                        }];
                    }
                }
                else if ([method isEqualToString:BridgedMethod_getAbSdkVersion]) {
                    NSString *versions = [self.associatedTrack.abTester allExposedABVersions];
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:versions];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
                    }];
                } else if ([method isEqualToString:BridgedMethod_setExternalABVersions]) {
                    NSString *vids = [methodParams objectAtIndex:0];
                    [self.associatedTrack setExternalABVersion:vids];
                } else if ([method isEqualToString:BridgedMethod_getAllAbTestConfigs]) {
                    NSString *abConfigStr = @"";
                    NSDictionary *abConfigJSON = [self.associatedTrack.abTester allABTestConfigs2];
                    NSData *abConfigData = [NSJSONSerialization dataWithJSONObject:abConfigJSON options:0 error:nil];
                    if (abConfigData.length > 0) {
                        abConfigStr = [[NSString alloc] initWithData:abConfigData encoding:NSUTF8StringEncoding];
                    }
                    NSString *js = [self JSWithCallbackID:JSCallbackID returnString:abConfigStr];
                    [msgWebView evaluateJavaScript:js completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
                    }];
                }
                
                else if ([method isEqualToString:BridgedMethod_setNativeAppId]) {
                    NSString *appId = [methodParams objectAtIndex:0];
                    self.boundAppID = appId;
                }
            }
        } @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"%@", exception);
#endif
        }
    }
}


- (NSString *)JSWithCallbackID:(NSString *)callbackID returnString:(NSString *)returnString {
    NSString *js;
    if (callbackID) {
        NSString *jsRunCallback = [NSString stringWithFormat:@";AppLogBridge.callbackMemo.getCallback('%@')('%@');", callbackID, returnString];
        NSString *jsRemoveCallback = [NSString stringWithFormat:@";AppLogBridge.callbackMemo.removeCallback('%@');", callbackID];
        js = [jsRunCallback stringByAppendingString:jsRemoveCallback];
    }
    return js;
}

- (NSString *)JSWithCallbackID:(NSString *)callbackID returnNumber:(NSNumber *)returnNumber {
    NSString *js;
    if (callbackID) {
        NSString *jsRunCallback = [NSString stringWithFormat:@";AppLogBridge.callbackMemo.getCallback('%@')(%@);", callbackID, returnNumber];
        NSString *jsRemoveCallback = [NSString stringWithFormat:@";AppLogBridge.callbackMemo.removeCallback('%@');", callbackID];
        js = [jsRunCallback stringByAppendingString:jsRemoveCallback];
    }
    return js;
}

@end
