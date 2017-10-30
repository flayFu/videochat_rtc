//
//  ARTCVideoChatViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCVideoChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CAPSPageMenu.h"
#import "GxpMicListController.h"
#import "GxpUserController.h"
#import "Masonry.h"
#import "GxpChatViewController.h"
#import "GxpUser.h"
#import "InputView.h"
#import "AlertHelper.h"
#import "RTCVideoTrack+MetaData.h"
#import "GxpUserManager.h"
#import "GxpMsgProducer.h"
#define SERVER_HOST_URL @"https://appr.tc"

@interface ARTCVideoChatViewController ()<UITableViewDelegate, UITableViewDataSource, CAPSPageMenuDelegate>{
    CAPSPageMenu *_pageMenu;
    GxpMicListController *_vc1;
    GxpUserController *_vc2;
    GxpChatViewController *_chatVc;
}

@end
@implementation ARTCVideoChatViewController
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}
- (void)viewDidLoad {
    
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.isZoom = NO;
    self.isAudioMute = NO;
    self.isVideoMute = NO;
    self.audioButton.selected = YES;
    [self.videoButton.layer setCornerRadius:20.0f];
    [self.hangupButton.layer setCornerRadius:20.0f];
    
    //Add Tap to hide/show controls
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //Add Double Tap to zoom
//    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
//    [tapGestureRecognizer setNumberOfTapsRequired:2];
//    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    [self.remoteView setDelegate:self];
    [self.localView setDelegate:self];

    
    
    _table.delegate = self;
    _table.dataSource = self;
    _users = [NSMutableArray new];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //page menu
    _vc1 = [storyBoard instantiateViewControllerWithIdentifier:@"MicList"];
    _vc1.title = @"麦序列表";
    _vc2 =[storyBoard instantiateViewControllerWithIdentifier:@"User"];
    _vc2.title = @"用户列表";
    _chatVc = [[GxpChatViewController alloc]initWithNibName:@"GxpChatViewController" bundle:nil];
    _chatVc.title = @"聊天列表";
    _chatVc.webSocket = self.client.webSocket;
//    _vc2.selfUserId = self.roomName;
//    _vc2.users = _users;
    NSArray *controllerArray = @[_vc1,_vc2,_chatVc];
    
    NSDictionary *parameters = @{
                                 CAPSPageMenuOptionScrollMenuBackgroundColor: [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0],
                                 CAPSPageMenuOptionViewBackgroundColor: [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:1.0],
                                 CAPSPageMenuOptionSelectionIndicatorColor: [UIColor orangeColor],
                                 CAPSPageMenuOptionBottomMenuHairlineColor: [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0],
                                 CAPSPageMenuOptionMenuItemFont: [UIFont fontWithName:@"HelveticaNeue" size:13.0],
                                 CAPSPageMenuOptionMenuHeight: @(40.0),
                                 CAPSPageMenuOptionMenuItemWidth: @(90.0),
                                 CAPSPageMenuOptionCenterMenuItems: @(YES)
                                 };

    _pageMenu = [[CAPSPageMenu alloc] initWithViewControllers:controllerArray frame:CGRectMake(0.0, CGRectGetMaxY(self.localView.frame), self.view.frame.size.width, self.view.frame.size.height) options:parameters];
    _pageMenu.delegate = self;
    _pageMenu.view.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:_pageMenu.view];

    [_pageMenu.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_localView.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    

    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}
//- (void)addUser:(NSNotification *)notification{
//    NSDictionary *dict = notification.userInfo;
//    GxpUser *user = [GxpUser new];
//    user.userId = dict[@"userId"];
//    [_users addObject:user];
//}
- (void)didMoveToPage:(UIViewController *)controller index:(NSInteger)index{
//    if(index == 1){
//        GxpUserController *userController = (GxpUserController *)controller;
//        userController.users = _users;
//    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self sendTextView];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    //Connect to the room
    [self disconnect];
    // pass
    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    [self.client setServerHostUrl:SERVER_HOST_URL];
    [self.client connectToRoomWithId:self.roomName options:nil];//其他默认为1，输入的 房间名 作为 用户名 和 用户 id
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)orientationChanged:(NSNotification *)notification{
    [self videoView:self.localView didChangeVideoSize:self.localVideoSize];
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//视频公聊搞起
- (IBAction)requestPublicVideo:(id)sender {
    [self.client micVideoOn];
}
- (IBAction)requestPublicVideoDown:(id)sender {
    [self.client micVideoDown];
}

//- (NSString*)dictionaryToJson:(NSDictionary *)dic
//
//{
//    
//    NSError *parseError = nil;
//    //    [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
//    NSString *STR = DICTTOSTR(dic);
//    return STR;
//    //    return nil;
//}


- (void)setRoomName:(NSString *)roomName {
    _roomName = roomName;
    self.roomUrl = [NSString stringWithFormat:@"%@/r/%@", SERVER_HOST_URL, roomName];
}

- (void)disconnect {
    if (self.client) {
        if (self.localVideoTrack) [self.localVideoTrack removeRenderer:self.localView];
        if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
        if (self.secRemoteVieoTrack) [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
        
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
        
        self.secRemoteVieoTrack = nil;
        [self.secRemoteView renderFrame:nil];
        
        [self.client disconnect];
    }
}

- (void)remoteDisconnected {
    if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
    self.remoteVideoTrack = nil;
    [self.remoteView renderFrame:nil];
    [self videoView:self.localView didChangeVideoSize:self.localVideoSize];
    
}
#pragma mark uitableview delegate and datasource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"person"];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
- (void)toggleButtonContainer {
    [self.view endEditing:YES];
    [self.client.webSocket send:[GxpMsgProducer pubOfflineSenderId:[GxpUserManager sharedInstance].selfId senderName:[GxpUserManager sharedInstance].selfName onMic:YES]];
    [self.client.webSocket close];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    [UIView animateWithDuration:0.3f animations:^{
        if (self.buttonContainerViewLeftConstraint.constant <= -40.0f) {
            [self.buttonContainerViewLeftConstraint setConstant:20.0f];
            [self.buttonContainerView setAlpha:1.0f];
        } else {
            [self.buttonContainerViewLeftConstraint setConstant:-40.0f];
            [self.buttonContainerView setAlpha:0.0f];
        }
        [self.view layoutIfNeeded];
    }];
}

- (void)zoomRemote {
    //Toggle Aspect Fill or Fit
    self.isZoom = !self.isZoom;
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (IBAction)audioButtonPressed:(id)sender {
    //TODO: this change not work on simulator (it will crash)
    UIButton *audioButton = sender;
    if (self.isAudioMute) {
        [self.client unmuteAudioIn];
//        [audioButton setImage:[UIImage imageNamed:@"audioOn"] forState:UIControlStateNormal];
        audioButton.selected = YES;
        self.isAudioMute = NO;
    } else {
        [self.client muteAudioIn];
        audioButton.selected = NO;
//        [audioButton setImage:[UIImage imageNamed:@"audioOff"] forState:UIControlStateNormal];
        self.isAudioMute = YES;
    }
}

- (IBAction)videoButtonPressed:(id)sender {
    UIButton *videoButton = sender;
    if (self.isVideoMute) {
//        [self.client unmuteVideoIn];
        [self.client swapCameraToFront];
        [videoButton setImage:[UIImage imageNamed:@"videoOn"] forState:UIControlStateNormal];
        self.isVideoMute = NO;
    } else {
        [self.client swapCameraToBack];
        //[self.client muteVideoIn];
        //[videoButton setImage:[UIImage imageNamed:@"videoOff"] forState:UIControlStateNormal];
        self.isVideoMute = YES;
    }
}
//开启或者关闭视频
- (IBAction)hangupButtonPressed:(UIButton *)sender {
    self.client.turnOn = !self.client.turnOn;
    sender.selected = self.client.turnOn;
//    NSLog(@"title %@",sender.currentTitle);
//    [self disconnect];
//    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}
- (void)sendTextView{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 30)];
    view.backgroundColor = [UIColor redColor];
    UITextField *inputTf = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(view.frame) - 50, 30)];
    inputTf.backgroundColor = [UIColor redColor];
    [view addSubview:inputTf];
    
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake(CGRectGetWidth(inputTf.frame), 0, 50, 30);
    [sendBtn setTitle:@"send" forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:sendBtn];
    [self.view addSubview:view];
}
- (void)sendText{
    [self.client sendText];
}
- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack isAdmin:(BOOL)isAdmin{
    
    if (localVideoTrack) {
        NSLog(@"收到本地视频");
        if (isAdmin) {
            NSLog(@"在顶部渲染房主视频");
            [self.remoteVideoTrack removeRenderer:self.remoteView];
            self.remoteVideoTrack = nil;
            [self.remoteView renderFrame:nil];
            
            self.remoteVideoTrack = localVideoTrack;
            [self.remoteVideoTrack addRenderer:self.remoteView];
        }else{//如果不是房主的话 说明 申请上麦了 从左往右开始搞起
            if ([GxpUserManager sharedInstance].allVideos == 1) {//算上自己只有一个，也就是房主没开视频
                NSLog(@"本地视频渲染在第一个上 %@",localVideoTrack);
                [self.localVideoTrack removeRenderer:self.localView];
                self.localVideoTrack = nil;
                [self.localView renderFrame:nil];
                
                self.localVideoTrack = localVideoTrack;
                [self.localVideoTrack addRenderer:self.localView];
            }else if ([GxpUserManager sharedInstance].allVideos == 2){//算上自己有两个，也就是房主开视频了
                
                NSLog(@"本地视频渲染在第一个上 %@",localVideoTrack);
                [self.localVideoTrack removeRenderer:self.localView];
                self.localVideoTrack = nil;
                [self.localView renderFrame:nil];
                [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
                self.secRemoteVieoTrack = nil;
                [self.secRemoteView renderFrame:nil];
                
                
                self.localVideoTrack = localVideoTrack;
                [self.localVideoTrack addRenderer:self.localView];
            }else if ([GxpUserManager sharedInstance].allVideos == 3){
                NSLog(@"本地视频渲染在第二个上");
                [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
                self.secRemoteVieoTrack = nil;
                [self.secRemoteView renderFrame:nil];
                
                self.secRemoteVieoTrack = localVideoTrack;
                [self.secRemoteVieoTrack addRenderer:self.secRemoteView];
            }else if([GxpUserManager sharedInstance].allVideos == 0){
                NSLog(@"没有视频需要显示");
                [self.remoteVideoTrack removeRenderer:self.remoteView];
                self.remoteVideoTrack = nil;
                [self.remoteView renderFrame:nil];
                
                [self.localVideoTrack removeRenderer:self.localView];
                self.localVideoTrack = nil;
                [self.localView renderFrame:nil];
                
                [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
                self.secRemoteVieoTrack = nil;
                [self.secRemoteView renderFrame:nil];
                
            }else{
                NSLog(@"已有三个无法渲染 本地");
            }
        }

    }
}
//房主肯定是第一个远端视频流
- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTracks:(NSArray *)remoteVideoTracks isAdmin:(BOOL)isAdmin{
    if (remoteVideoTracks.count == 0) {
        return ;
    }
    NSLog(@"远端视频流 %@",remoteVideoTracks);//房主肯定在第一个
    
    //渲染
    if ([[GxpUserManager sharedInstance].adminId isEqualToString:[GxpUserManager sharedInstance].selfId]) {//自己是房主
        for (int i = 0; i<remoteVideoTracks.count; i++) {
            RTCVideoTrack *videoTrack = remoteVideoTracks[i];
            if (i == 0) {
                NSLog(@"第一个远端 %@",videoTrack);
                [self.localVideoTrack removeRenderer:self.localView];
                self.localVideoTrack = nil;
                [self.localView renderFrame:nil];
                
                self.localVideoTrack = videoTrack;
                [self.localVideoTrack addRenderer:self.localView];
            }
            
            if (i == 1) {
                NSLog(@"第二个远端 %@",videoTrack);
                [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
                self.secRemoteVieoTrack = nil;
                [self.secRemoteView renderFrame:nil];
                
                self.secRemoteVieoTrack = videoTrack;
                [self.secRemoteVieoTrack addRenderer:self.secRemoteView];

            }
            
            if (i >= 2) {
                NSLog(@"怎么有超过2人上麦了");
            }
        }

    }else{
        NSLog(@"不是房主");
        for (int i = 0; i<remoteVideoTracks.count; i++) {
            RTCVideoTrack *videoTrack = remoteVideoTracks[i];
            if (i == 0) {//是房主的渲染
                NSLog(@"渲染房主视频 %@",videoTrack);
                [self.remoteVideoTrack removeRenderer:self.remoteView];
                self.remoteVideoTrack = nil;
                [self.remoteView renderFrame:nil];
                
                self.remoteVideoTrack = videoTrack;
                [self.remoteVideoTrack addRenderer:self.remoteView];
            }
            
            if (i == 1) {
                NSLog(@"渲染上麦者的视频");
                [self.localVideoTrack removeRenderer:self.localView];
                self.localVideoTrack = nil;
                [self.localView renderFrame:nil];
                
                self.localVideoTrack = videoTrack;
                [self.localVideoTrack addRenderer:self.localView];
            }
            
            if (i == 2) {
                [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
                self.secRemoteVieoTrack = nil;
                [self.secRemoteView renderFrame:nil];
                
                self.secRemoteVieoTrack = videoTrack;
                [self.secRemoteVieoTrack addRenderer:self.secRemoteView];
            }
            
            if (i > 2) {
                NSLog(@"怎么有超过2人上麦了");
            }
        }

    }
    //清除
    if ([GxpUserManager sharedInstance].allVideos == 1) {
        NSLog(@"清除左1");
        [self.localVideoTrack removeRenderer:self.localView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];

        [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
        self.secRemoteVieoTrack = nil;
        [self.secRemoteView renderFrame:nil];
    }else if ([GxpUserManager sharedInstance].allVideos == 2){
        NSLog(@"清除左2");
        [self.secRemoteVieoTrack removeRenderer:self.secRemoteView];
        self.secRemoteVieoTrack = nil;
        [self.secRemoteView renderFrame:nil];
    }
}


- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [self disconnect];
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {

}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self.client];
}
@end
