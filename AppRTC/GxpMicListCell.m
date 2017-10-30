//
//  GxpMicListCell.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpMicListCell.h"
#import "AppDelegate.h"
#import "MMAlertView.h"
#import "AlertHelper.h"
#import "GxpUser.h"
#import "GxpUserManager.h"
#import "Macros.h"
//#define MAX_VIDEO_COUNT 3

@implementation GxpMicListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)agreeMicOn:(UIButton *)sender {
    if ([GxpUserManager sharedInstance].allVideos >= MAX_VIDEO_COUNT) {
        [AlertHelper alertWithText:@"上麦人数已达上限"];
    }else{
        AppDelegate *de = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (!de.turnOn) {
            [AlertHelper alertWithText:@"请先开启视频"];
        }
        if ([sender.currentTitle isEqualToString:@"已同意"]) {
            NSLog(@"已经同意过了别点了");
            return;
        }
        //同意谁上麦
        [self.agreeBtn setTitle:@"已同意" forState:UIControlStateNormal];
        [self performSelector:@selector(sendAgreeMicOn) withObject:self afterDelay:2];
    }
    
}
//让这个用户公聊下麦
- (IBAction)forbidPubOnMic:(id)sender {
    [[GxpUserManager sharedInstance].onMicVideo enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:_userId.text]) {
            [[GxpUserManager sharedInstance].onMicVideo removeObject:obj];
        }
    }];
    
//    [[GxpUserManager sharedInstance].onMicVideo removeObject:_userId.text];
    if ([[GxpUserManager sharedInstance].selfId isEqualToString:_userId.text]) {
        NSLog(@"自己下麦");
        [[GxpUserManager sharedInstance].miclist enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userId isEqualToString:_userId.text]) {
                [[GxpUserManager sharedInstance].miclist removeObject:obj];
                [[GxpUserManager sharedInstance].userList addObject:obj];
            }
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:nil];
        }];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"initiativePubDownMic" object:self userInfo:@{@"userId":_userId.text}];
    }else{
        [[NSNotificationCenter defaultCenter]postNotificationName:@"forbidPubOnMic" object:self userInfo:@{@"userId":_userId.text}];

    }
}

- (void)sendAgreeMicOn{
    [[GxpUserManager sharedInstance].onMicVideo addObject:_userId.text];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"agreePubMicOn" object:self userInfo:@{@"userId":_userId.text}];
}
@end
