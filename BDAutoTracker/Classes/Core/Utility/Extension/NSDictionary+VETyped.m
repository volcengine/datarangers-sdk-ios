//
//  NSDictionary+VETyped.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/25.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "NSDictionary+VETyped.h"

@implementation NSDictionary (VETyped)


- (BOOL)vetyped_boolForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        return [value boolValue];
    }

    return NO;
}

- (NSInteger)vetyped_integerForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value integerValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value integerValue];
    }
    return 0;
}

- (double)vetyped_doubleForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value doubleValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value doubleValue];
    }

    return 0.0;
}

- (long long)vetyped_longlongValueForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value longLongValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value longLongValue];
    }

    return 0;
}

- (NSString *)vetyped_stringForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

- (NSDictionary *)vetyped_dictionaryForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSMapTable class]]) {
        NSMapTable *table = value;
        return table.dictionaryRepresentation;
    }
    return nil;
}

- (NSArray *)vetyped_arrayForKey:(NSString *)key
{
    id value = [self objectForKey:key];

    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    
    if ([value isKindOfClass:[NSHashTable class]]) {
        NSHashTable *table = value;
        return table.allObjects;
    }
    
    if ([value isKindOfClass:[NSSet class]]) {
        NSSet *table = value;
        return table.allObjects;
    }

    return nil;
}







@end
