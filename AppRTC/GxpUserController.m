//
//  GxpUserController.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpUserController.h"
#import "GxpUserCell.h"
#import "GxpUser.h"
#import "GxpUserManager.h"
@interface GxpUserController ()

@end

@implementation GxpUserController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    _users = [NSMutableArray new];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(shouldReload) name:@"someonlogin" object:@"logIn"];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(shouldReload) name:@"all" object:nil];


}

- (void)shouldReload{
    [_table reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [GxpUserManager sharedInstance].userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GxpUser *user = [GxpUserManager sharedInstance].userList[indexPath.row];//取出数据
    GxpUserCell *cell;
    if ([user.userId isEqualToString:[GxpUserManager sharedInstance].selfId]) {//如果是自己
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserSelf" forIndexPath:indexPath];
        cell.pubMicBtn.hidden = NO;
        cell.priMicBtn.hidden = NO;
        cell.userId.text = user.userId;
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserSelf" forIndexPath:indexPath];
        cell.pubMicBtn.hidden = YES;
        cell.priMicBtn.hidden = YES;
        cell.userId.text = user.userId;

    }
    
    return cell;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
