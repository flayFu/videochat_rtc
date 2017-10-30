//
//  GxpMsgManager.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/9.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpMsgManager.h"
static GxpMsgManager* _instance = nil;
@implementation GxpMsgManager
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        _instance.msgs = [NSMutableArray new];
    });
    return _instance;
}

@end
