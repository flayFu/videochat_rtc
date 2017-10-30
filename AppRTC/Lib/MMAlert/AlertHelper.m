//
//  AlertHelper.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/16.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "AlertHelper.h"
#import "MMAlertView.h"
@implementation AlertHelper
+ (void)alertWithText:(NSString *)text{
    NSArray *items =
    @[MMItemMake(@"确认", MMItemTypeNormal, nil)];
    
    MMAlertView *alertView = [[MMAlertView alloc] initWithTitle:@"提示信息"
                                                         detail:text
                                                          items:items];
    [alertView show];
}
@end
