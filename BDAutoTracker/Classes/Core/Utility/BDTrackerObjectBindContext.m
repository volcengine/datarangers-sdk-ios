//
//  BDTrackerObjectBindContext.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/31.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "BDTrackerObjectBindContext.h"
#import <objc/runtime.h>

@implementation BDAutoTrackerBindingContext {
    NSMutableDictionary *undefined_values;
    NSLock *syncLocker;
}

- (instancetype)init
{
    if (self = [super init]) {
        undefined_values = [NSMutableDictionary dictionary];
        syncLocker = [NSLock new];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [syncLocker lock];
    [undefined_values setValue:value forKey:key];
    [syncLocker unlock];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    [syncLocker lock];
    @try {
        return [undefined_values valueForKey:key];
    } @finally {
        [syncLocker unlock];
    }
    
}

@end

@implementation NSObject (BDAutoTrackBinding)

- (void)setBdtracker_context:(BDAutoTrackerBindingContext *)bdtracker_context
{
    objc_setAssociatedObject(self, @selector(bdtracker_context), bdtracker_context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDAutoTrackerBindingContext *)bdtracker_context {
    BDAutoTrackerBindingContext* context = objc_getAssociatedObject(self, @selector(bdtracker_context));
    if (!context) {
        context = [BDAutoTrackerBindingContext new];
        [self setBdtracker_context:context];
    }
    return context;
}

- (NSString *)bdtracker_pointerId
{
    return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

@end
