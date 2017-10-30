//
//  GxpUserCell.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpUserCell.h"
#import "GxpUserManager.h"
#import "AlertHelper.h"
#import "Macros.h"
//#define MAX_VIDEO_COUNT 3

@implementation GxpUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
//申请上麦
- (IBAction)pubMicOn:(id)sender {
    if ([GxpUserManager sharedInstance].allVideos >= MAX_VIDEO_COUNT || [GxpUserManager sharedInstance].forbided) {
        [AlertHelper alertWithText:@"你不能上麦"];
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pubMicOn" object:@"gxpusercell" userInfo:@{@"userId":_userId}];
    }
}
- (IBAction)priMicOn:(id)sender {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"privatePubMicOn" object:@"gxpusercell" userInfo:@{@"userId":_userId}];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
