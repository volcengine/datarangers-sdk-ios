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

static void rangers_console_log(RangersLogObject *log)
{
    NSMutableString *output = [NSMutableString new];
    NSString *datePart = rangers_console_dateformat(log.timestamp);
    [output appendString:datePart];
    
    NSString *filterTag = @"[Rangers]";
    if ([log.module length] > 0) {
        filterTag = [NSString stringWithFormat:@"[Rangers:%@]",log.module];
    }
    [output appendFormat:@" %@", filterTag];
    
    NSString *flag = @"D";
    if (log.flag == RANGERS_LOG_FLAG_ERROR) {
        flag = @"E";
    } else if (log.flag == RANGERS_LOG_FLAG_WARNING) {
        flag = @"W";
    }
    
    [output appendFormat:@"<%@>",flag];
//    [output appendFormat:@"(%@:%ld)",log.file, log.line];
    [output appendFormat:@" %@",log.message?:@""];
    
    fprintf(stdout, "%s", [output UTF8String]);
    fprintf(stdout, "\r\n");
    fflush(stdout);
}




@implementation RangersConsoleLogger



- (void)log:(nonnull RangersLogObject *)log {
    rangers_console_log(log);
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
