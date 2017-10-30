//
//  GxpMicListController.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpMicListController.h"
#import "GxpUserManager.h"
#import "GxpMicListCell.h"
#import "GxpUser.h"
@interface GxpMicListController (){

}

@end

@implementation GxpMicListController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(shouldReload) name:@"miclist" object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(shouldReload) name:@"all" object:nil];
    NSLog(@"add no--------");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return [GxpUserManager sharedInstance].miclist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GxpMicListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MicList" forIndexPath:indexPath];
    GxpUser *user = [GxpUserManager sharedInstance].miclist[indexPath.row];
    cell.userId.text = user.userId;
    if ([[GxpUserManager sharedInstance].adminId isEqualToString:user.userId]) {//隐藏房主，房主无须同意
        cell.agreeBtn.hidden = YES;
        cell.forbidOnMic.hidden = YES;
    }else{//如果这个用户不是房主
        if([[GxpUserManager sharedInstance].selfId isEqualToString:[GxpUserManager sharedInstance].adminId]){//当前登录的是房主显示同意,禁麦按钮（之前排除了房主）
            cell.forbidOnMic.hidden = NO;
            cell.agreeBtn.hidden = NO;//只有房主才有同意的权限
            __block BOOL hasAgreeMicOn = NO;
            [[GxpUserManager sharedInstance].onMicVideo enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqualToString:user.userId]) {
                    hasAgreeMicOn = YES;
                }
            }];
            
            if (hasAgreeMicOn) {
                [cell.agreeBtn setTitle:@"已同意" forState:UIControlStateNormal];
            }else{
                [cell.agreeBtn setTitle:@"同意" forState:UIControlStateNormal];
            }
        }else{
            cell.forbidOnMic.hidden = YES;
            cell.agreeBtn.hidden = YES;
            if ([[GxpUserManager sharedInstance].selfId isEqualToString:user.userId]) {
                cell.forbidOnMic.hidden = NO;
            }

        }
        
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
