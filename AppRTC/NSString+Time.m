//
//  NSString+Time.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/10.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "NSString+Time.h"

@implementation NSString (Time)
+ (NSString *)time{
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
    return [formatter stringFromDate:date];;
}
@end
