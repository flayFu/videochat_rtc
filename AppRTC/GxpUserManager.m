//
//  GxpUserManager.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/4.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpUserManager.h"
#import "GxpUser.h"
@implementation GxpUserManager

static GxpUserManager* _instance = nil;
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        _instance.userList = [NSMutableArray new];
        _instance.miclist = [NSMutableArray new];
        _instance.onMicVideo = [NSMutableArray new];
    });
    return _instance;
}
- (void)setAllVideos:(NSUInteger)allVideos{
    _allVideos = allVideos;
    NSLog(@"现在共有 %lu 个视频显示",(unsigned long)_allVideos);
}
- (void)removeUser:(NSString *)userId{
    [_userList enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            [_userList removeObject:obj];
        }
    }];
    
    [_miclist enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            [_miclist removeObject:obj];
        }
    }];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
}

- (NSMutableArray *)allUsers{
    NSMutableArray *array = [NSMutableArray new];
    [array addObjectsFromArray:_userList];
    [array addObjectsFromArray:_miclist];
    NSLog(@"当前登陆的所有人 before %@",array);

//    [array enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSLog(@"obj user id = %@",obj.userId);
//
//        if ([obj.userId isEqualToString:_adminId]) {
//            NSLog(@"删除房主");
//            [array removeObject:obj];
//        }
//        if ([obj.userId isEqualToString:[GxpUserManager sharedInstance].selfId]) {
//            NSLog(@"删除自己");
//            [array removeObject:obj];
//        }
//    }];
    
    for (NSUInteger i = 0; i < array.count; i++) {
        GxpUser *obj = array[i];
        if ([obj.userId isEqualToString:_adminId]) {
            NSLog(@"删除房主");
            [array removeObject:obj];
        }
        
    }
    
    for (NSUInteger i = 0; i < array.count; i++) {
        GxpUser *obj = array[i];
        
        if ([obj.userId isEqualToString:[GxpUserManager sharedInstance].selfId]) {
            NSLog(@"删除自己");
            [array removeObject:obj];
        }
        
    }

    NSLog(@"当前登陆的所有人 after %@",array);
    return array;
}
@end
