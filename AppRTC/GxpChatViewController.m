//
//  GxpChatViewController.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/9.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "GxpChatViewController.h"
#import "IQKeyboardManager.h"
#import "GxpMsgManager.h"
#import "GxpUserManager.h"
#import "GxpMsgProducer.h"
#import "InputView.h"
#import "GxpMsgComeCell.h"
#import "GxpMsgGoCell.h"
#import "GxpUser.h"
#import "GxpMsg.h"
#import "NSString+Time.h"
@interface GxpChatViewController ()<UITableViewDelegate, UITableViewDataSource,InputViewDelegate>{
    InputView *_inputView;
    UITableView *_table;
    UITableView *_users;
}

@end

@implementation GxpChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initTable];
    self.automaticallyAdjustsScrollViewInsets = NO;
//    _inputView = [[NSBundle mainBundle]loadNibNamed:@"InputView" owner:self options:nil][0];
//    _inputView.delegate = self;
//    _inputView.frame = CGRectMake(0, 50, [UIScreen mainScreen].bounds.size.width, 100);
//    _inputView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:_inputView];
//    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
//    [IQKeyboardManager sharedManager].enableDebugging = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self becomeFirstResponder];
    [_table reloadData];
}
- (void)initTable{
    _table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100) style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    [self.view addSubview:_table];
    
    [_table registerNib:[UINib nibWithNibName:@"GxpMsgComeCell" bundle:nil] forCellReuseIdentifier:@"msgcome"];
    [_table registerNib:[UINib nibWithNibName:@"GxpMsgGoCell" bundle:nil] forCellReuseIdentifier:@"msggo"];
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (UIView *)inputAccessoryView{
    if (!_inputView) {
        CGFloat y = [UIScreen mainScreen].bounds.size.height/2 - 120 - 34 - 100;
        _inputView = [[[NSBundle mainBundle]loadNibNamed:@"InputView" owner:self options:nil] firstObject];
        _inputView.frame = CGRectMake(0, y, [UIScreen mainScreen].bounds.size.width, 100);
        _inputView.delegate = self;
    }
    return _inputView;
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView.tag == 1) {
       return  [GxpUserManager sharedInstance].allUsers.count;
    }
    return [GxpMsgManager sharedInstance].msgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == 1) {
        UITableViewCell *userCell = [tableView dequeueReusableCellWithIdentifier:@"user"];
        if (!userCell) {
            userCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"user"];
        }
        GxpUser *user = [GxpUserManager sharedInstance].allUsers[indexPath.row];
        userCell.textLabel.text = user.userId;
        return userCell;
    }
    GxpMsg *msg = [GxpMsgManager sharedInstance].msgs[indexPath.row];
    if (msg.isCome) {
        GxpMsgComeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"msgcome"];
        cell.msgLabel.text = msg.msg;
        cell.timeLabel.text = [NSString time];
        return cell;
    }else{
        GxpMsgGoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"msggo"];
        cell.msgLabel.text = msg.msg;
        cell.timeLabel.text = [NSString time];
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView.tag == 1) {
        GxpUser *user = [GxpUserManager sharedInstance].allUsers[indexPath.row];
        _inputView.sendToId = user.userId;
        [_users removeFromSuperview];
    }
}
- (void)xp_inputView:(InputView *)inputview msgToSend:(NSString *)msg private:(BOOL)privateMsg to:(NSString *)target{
//    [self.webSocket send:[GxpMsgProducer textMsgSenderName:[GxpUserManager sharedInstance].selfName senderId:[GxpUserManager sharedInstance].selfId TargetId:@"所有人" text:@"我是小四"]];
    
    if (privateMsg) {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"sendtext" object:self userInfo:@{@"msg":msg,@"target":target,@"private":@(privateMsg)}];
    }else{
        [[NSNotificationCenter defaultCenter]postNotificationName:@"sendtext" object:self userInfo:@{@"msg":msg}];
    }
}

- (void)showUsers{
    [self.view endEditing:YES];
    if (!_users) {
        _users = [[UITableView alloc]initWithFrame:CGRectMake(12, 0, [UIScreen mainScreen].bounds.size.width - 24, 300) style:UITableViewStylePlain];
        _users.backgroundColor = [UIColor greenColor];
        _users.tag = 1;
        _users.delegate = self;
        _users.dataSource = self;
        _users.separatorColor = [UIColor colorWithRed:216/255.0 green:216/255.0 blue:216/255.0 alpha:1];
    }
    [[UIApplication sharedApplication].keyWindow addSubview:_users];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
