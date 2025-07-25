//
//  RangersConsoleLogger.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/15.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import "RangersConsoleLogger.h"
#import "RangersLogManager.h"

static NSString *rangers_console_dateformat(NSTimeInterval ts)
{
    static NSCalendar    *gCalendar;
    static NSUInteger    gCalendarUnitFlags;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gCalendar = [NSCalendar autoupdatingCurrentCalendar];
        
        gCalendarUnitFlags = 0;
        gCalendarUnitFlags |= NSCalendarUnitYear;
        gCalendarUnitFlags |= NSCalendarUnitMonth;
        gCalendarUnitFlags |= NSCalendarUnitDay;
        gCalendarUnitFlags |= NSCalendarUnitHour;
        gCalendarUnitFlags |= NSCalendarUnitMinute;
        gCalendarUnitFlags |= NSCalendarUnitSecond;
    });
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
    NSDateComponents *components = [gCalendar components:gCalendarUnitFlags fromDate:date];
    NSTimeInterval epoch = [date timeIntervalSinceReferenceDate];
    int milliseconds = (int)((epoch - floor(epoch)) * 1000);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld:%03d",(long)components.hour,(long)components.minute,(long)components.second, milliseconds];
}

static NSString* rangers_console_log(RangersLogObject *log)
{
    NSMutableString *output = [NSMutableString new];
    NSString *datePart = rangers_console_dateformat(log.timestamp);
    [output appendString:datePart];
    
    NSString *filterTag = @"[Rangers]";
    if ([log.appId length] > 0) {
        filterTag = [NSString stringWithFormat:@"[Rangers:%@]",log.appId];
    }
    [output appendFormat:@" %@", filterTag];
    
    NSString *flag = @"DEBUG";
    if (log.flag == VETLOG_FLAG_INFO) {
        flag = @" INFO";
    } else if (log.flag == VETLOG_FLAG_WARN) {
        flag = @" WARN";
    } else if (log.flag == VETLOG_FLAG_ERROR) {
        flag = @"ERROR";
    }
    
    [output appendFormat:@"<%@>",flag];
    if (log.module.length > 0) {
        [output appendFormat:@"[%@]",log.module];
    }
    [output appendFormat:@" %@",log.message?:@""];
    return output;
}




@implementation RangersConsoleLogger

+ (void)load
{
    [RangersLogManager registerLogger:[self class]];
}

- (void)log:(nonnull RangersLogObject *)log {
    NSLog(@"%@",rangers_console_log(log));
}

+ (NSString *)logToString:(RangersLogObject *)log
{
    return rangers_console_log(log);
}

- (nonnull dispatch_queue_t)queue {
    static dispatch_queue_t console_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        console_queue = dispatch_queue_create("rangers.logger.console", DISPATCH_QUEUE_SERIAL);
    });
    return console_queue;
}



    


@end
