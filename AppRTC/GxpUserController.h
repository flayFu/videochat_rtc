//
//  GxpUserController.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GxpUserController : UITableViewController
@property(nonatomic, strong)NSMutableArray *users;
@property (strong, nonatomic) IBOutlet UITableView *table;
@property(nonatomic, copy)NSString *selfUserId;
@end
