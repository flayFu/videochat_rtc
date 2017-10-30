//
//  GxpMicListController.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GxpMicListController : UITableViewController
@property (strong, nonatomic) IBOutlet UITableView *table;
@property(nonatomic, strong)NSMutableArray *users;
@end
