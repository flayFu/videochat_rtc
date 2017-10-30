//
//  GxpMicListCell.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GxpMicListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *agreeBtn;
@property (weak, nonatomic) IBOutlet UIButton *forbidOnMic;
@property (weak, nonatomic) IBOutlet UILabel *userId;
- (IBAction)agreeMicOn:(id)sender;

@end
