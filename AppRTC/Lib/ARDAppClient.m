/*
 * libjingle
 * Copyright 2014, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ARDAppClient.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ARDMessageResponse.h"
#import "ARDRegisterResponse.h"
#import "ARDSignalingMessage.h"
#import "ARDUtilities.h"
#import "ARDWebSocketChannel.h"
#import "RTCICECandidate+JSON.h"
#import "RTCICEServer+JSON.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoTrack.h"
#import <RTCAudioTrack.h>
#import "OrderedDictionary.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection+MetaData.h"
#import "RTCVideoTrack+MetaData.h"
#import "GxpMsgProducer.h"
#import "GxpUserManager.h"
#import "GxpMsgManager.h"
#import "GxpMsg.h"
#import "GxpUser.h"
#import "AlertHelper.h"
#import <RTCVideoTrack.h>
#import "AppDelegate.h"
typedef void(^regOk)(ARDMessageResponse *response);
// TODO(tkchin): move these to a configuration object.
static NSString *kARDRoomServerHostUrl =
    @"http://192.168.0.123:8080/Conference/";
static NSString *kARDRoomServerRegisterFormat =
    @"%@/join/%@";
static NSString *kARDRoomServerMessageFormat =
    @"%@/message/%@/%@";
static NSString *kARDRoomServerByeFormat =
    @"%@/leave/%@/%@";

static NSString *kARDDefaultSTUNServerUrl =
    @"stun:stun.l.google.com:19302";
// TODO(tkchin): figure out a better username for CEOD statistics.
static NSString *kARDTurnRequestUrl =
    @"https://computeengineondemand.appspot.com"
    @"/turn?username=iapprtc&key=4080218913";

static NSString *kARDAppClientErrorDomain = @"ARDAppClient";
static NSInteger kARDAppClientErrorUnknown = -1;
static NSInteger kARDAppClientErrorRoomFull = -2;
static NSInteger kARDAppClientErrorCreateSDP = -3;
static NSInteger kARDAppClientErrorSetSDP = -4;
static NSInteger kARDAppClientErrorNetwork = -5;
static NSInteger kARDAppClientErrorInvalidClient = -6;
static NSInteger kARDAppClientErrorInvalidRoom = -7;
//返回值 参数 都为空
typedef void(^emptyBlock)(void);
@interface ARDAppClient () <ARDWebSocketChannelDelegate,
RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, RTCDataChannelDelegate,SRWebSocketDelegate>{
    NSMutableArray *_data;
    RTCDataChannel *_rtcChannel;
    RTCDataChannel *_remoteChannel;
    BOOL _open;
    RTCMediaStream *_mediaStream;
    NSMutableArray *_peers;
    BOOL _secondOffer;//用户申请上麦，房主同意后进行二次offer
    NSMutableArray *_candidates;
    BOOL _getAllCandidates;
    BOOL _dealWithPubMicOn;
    BOOL _shangMai;//作为用户是否公聊上麦
    BOOL _privateMai;
//    BOOL _askForVideo;//别的用户要视频
    BOOL _dealWithLogIn;//正在处理登入事件(作为房主)
    BOOL _endOfferWithAdmin;//和房主的信令结束了
    BOOL _endOfferWithSomeOnePubMicOn;//和某个人的 offer video event 处理完了
    
    BOOL _dealWithPreLoginsAsUser;//当自己上麦后要向之前登陆的发送offer
    
    NSUInteger _allVideos;//共有几个视频正在显示
    NSMutableArray<RTCVideoTrack *> *_remoteVideoTracks;
    
    NSMutableArray *_pubMicOnUsers;//在和房主公聊的人,作为用户时处理
    
    NSMutableArray *_shangMaiUsers;//同意上麦的人们
    
    NSMutableArray *_logIns;//开启视频的时候有多少用户想要看房主的视频
    
    NSMutableArray *_users;//当自己上麦时需要向谁发送offer
    
    BOOL _onceCompelete;//完成一次
    
    
}
@property(nonatomic, copy) NSString *sendToId;
@property(nonatomic, copy) regOk reponse;
@property(nonatomic, strong) ARDWebSocketChannel *channel;
//@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic, strong) UILabel *log;
@property(nonatomic, assign) BOOL isTurnComplete;
@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, readonly) BOOL isRegisteredWithRoomServer;

@property(nonatomic, strong) NSString *roomId;
@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, copy) NSString *adminId;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, assign) BOOL isInitiator;

@property(nonatomic, assign) BOOL isAdmin;
@property(nonatomic, assign) BOOL isSpeakerEnabled;
@property(nonatomic, strong) NSMutableArray *iceServers;
@property(nonatomic, strong) NSURL *webSocketURL;
@property(nonatomic, strong) NSURL *webSocketRestURL;
@property(nonatomic, strong) RTCAudioTrack *defaultAudioTrack;
@property(nonatomic, strong) RTCVideoTrack *defaultVideoTrack;

@end

@implementation ARDAppClient

@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize serverHostUrl = _serverHostUrl;
@synthesize channel = _channel;
//@synthesize peerConnection = _peerConnection;
@synthesize factory = _factory;
@synthesize messageQueue = _messageQueue;
@synthesize isTurnComplete = _isTurnComplete;
@synthesize hasReceivedSdp  = _hasReceivedSdp;
@synthesize roomId = _roomId;
@synthesize clientId = _clientId;
@synthesize isInitiator = _isInitiator;
@synthesize isSpeakerEnabled = _isSpeakerEnabled;
@synthesize iceServers = _iceServers;
@synthesize webSocketURL = _websocketURL;
@synthesize webSocketRestURL = _websocketRestURL;

- (void)setTurnOn:(BOOL)turnOn{
    if (turnOn) {
        _allVideos++;
    }else{
        _allVideos--;
    }
    [GxpUserManager sharedInstance].allVideos = _allVideos;
    
    
    ((AppDelegate *)[UIApplication sharedApplication].delegate).turnOn = turnOn;
    _turnOn = turnOn;
    if (turnOn) {
        if (!_mediaStream) {
            NSLog(@"turn on _mediaStream");
            _mediaStream = [self createLocalMediaStream];
        }
        [_peers enumerateObjectsUsingBlock:^(RTCPeerConnection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj addStream:_mediaStream];
        }];
        [self.delegate appClient:self didReceiveLocalVideoTrack:[_mediaStream.videoTracks firstObject] isAdmin:_isAdmin];
        [self checkLogins];
    }else{
        
        [self.delegate appClient:self didReceiveLocalVideoTrack:nil isAdmin:_isAdmin];
        [_peers enumerateObjectsUsingBlock:^(RTCPeerConnection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeStream:_mediaStream];
        }];
    }
    

}

- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate {
  if (self = [super init]) {
      [[UIApplication sharedApplication]setIdleTimerDisabled:YES];
    _delegate = delegate;
      
      _shangMaiUsers = [NSMutableArray new];
      _pubMicOnUsers = [NSMutableArray new];
      _logIns = [NSMutableArray new];
      
      _endOfferWithAdmin = YES;
      _endOfferWithSomeOnePubMicOn = YES;
      _remoteVideoTracks = [NSMutableArray new];
    _factory = [[RTCPeerConnectionFactory alloc] init];
    _messageQueue = [NSMutableArray array];
    _iceServers = [self defaultSTUNServer];
      _getAllCandidates = NO;
      _candidates = [NSMutableArray new];
    _serverHostUrl = kARDRoomServerHostUrl;
    _isSpeakerEnabled = YES;
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(orientationChanged:)
                                                   name:@"UIDeviceOrientationDidChangeNotification"
                                                 object:nil];
      //申请公聊
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pubMicOn:) name:@"pubMicOn" object:@"gxpusercell"];
      //申请私聊
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(privatePubMicOn:) name:@"privatePubMicOn" object:@"gxpusercell"];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agreePubMicOn:) name:@"agreePubMicOn" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(agreePrivateMicOn:) name:@"agreePrivateMicOn" object:nil];

      [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sendText:) name:@"sendtext" object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forbidOnMic:) name:@"forbidPubOnMic" object:nil];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initiativePubDownMic:) name:@"initiativePubDownMic" object:nil];

  }
  return self;
}

- (void)forbidOnMic:(NSNotification *)notification{
    NSString *targetId = notification.userInfo[@"userId"];
    NSLog(@"禁止 %@ 上麦",targetId);
    [self.webSocket send:[GxpMsgProducer senderId:_userId forbidId:targetId]];
}

- (void)initiativePubDownMic:(NSNotification *)notification{
    NSString *sendrId = notification.userInfo[@"userId"];
    NSLog(@"主动下麦 %@",sendrId);
    [_peers enumerateObjectsUsingBlock:^(RTCPeerConnection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeStream:_mediaStream];
        NSLog(@"删除流");
    }];
    _allVideos--;
    [GxpUserManager sharedInstance].allVideos = _allVideos;
    [self.delegate appClient:self didReceiveRemoteVideoTracks:[_remoteVideoTracks copy] isAdmin:_isAdmin];
    [self.delegate appClient:self didReceiveLocalVideoTrack:nil isAdmin:NO];
    [self.webSocket send:[GxpMsgProducer publicMicVideoDownSenderName:sendrId senderId:sendrId]];//响应房主的下麦

}


- (void)agreePubMicOn:(NSNotification *)notification{
    _allVideos++;
    [GxpUserManager sharedInstance].allVideos = _allVideos;
    NSString *userId = notification.userInfo[@"userId"];
    _secondOffer = YES;
    [_shangMaiUsers addObject:userId];
    
    NSLog(@"_shangMaiUsers = %@ ----------",_shangMaiUsers);
    if (_shangMaiUsers.count > 1) {
        
    }else{
        _sendToId = userId;
        [self startSignalingIfReady];
    }
}

- (void)agreePrivateMicOn:(NSNotification *)notification{
    _allVideos++;
    [GxpUserManager sharedInstance].allVideos = _allVideos;
    NSString *userId = notification.userInfo[@"userId"];
    _secondOffer = YES;
    [_shangMaiUsers addObject:userId];
    
    NSLog(@" agreePrivateMicOn shangmai = %@",_shangMaiUsers);
    [self startSignalingIfReady];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  [self disconnect];
}

- (void)orientationChanged:(NSNotification *)notification {
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    if (UIDeviceOrientationIsLandscape(orientation) || UIDeviceOrientationIsPortrait(orientation)) {
//        //Remove current video track
//        RTCMediaStream *localStream = _peerConnection.localStreams[0];
//        [localStream removeVideoTrack:localStream.videoTracks[0]];
//        
//        RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
//        if (localVideoTrack) {
//            [localStream addVideoTrack:localVideoTrack];
//            [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
//        }
//        [_peerConnection removeStream:localStream];
//        [_peerConnection addStream:localStream];
//    }
}


- (void)setState:(ARDAppClientState)state {
  if (_state == state) {
    return;
  }
    
    
  _state = state;
  [_delegate appClient:self didChangeState:_state];
}

//改写这个实现
- (void)connectToRoomWithId:(NSString *)roomId
                    options:(NSDictionary *)options {
    _data = [NSMutableArray new];
  NSParameterAssert(roomId.length);
  NSParameterAssert(_state == kARDAppClientStateDisconnected);
  self.state = kARDAppClientStateConnecting;

  // Request TURN.
  __weak ARDAppClient *weakSelf = self;
  NSURL *turnRequestURL = [NSURL URLWithString:kARDTurnRequestUrl];
  [self requestTURNServersWithURL:turnRequestURL
                completionHandler:^(NSArray *turnServers) {
    ARDAppClient *strongSelf = weakSelf;
    [strongSelf.iceServers addObjectsFromArray:turnServers];
    NSLog(@"configure ice servers");
    strongSelf.isTurnComplete = YES;
  }];
    [self registerWithUsername:roomId];//加时站
}

- (void)disconnect {
  if (_state == kARDAppClientStateDisconnected) {
    return;
  }
  if (self.isRegisteredWithRoomServer) {
    [self unregisterWithRoomServer];
  }
  if (_channel) {
    if (_channel.state == kARDWebSocketChannelStateRegistered) {
      // Tell the other client we're hanging up.
      ARDByeMessage *byeMessage = [[ARDByeMessage alloc] init];
      NSData *byeData = [byeMessage JSONData];
      [_channel sendData:byeData];
    }
    // Disconnect from collider.
    _channel = nil;
  }
//  _clientId = nil;
  _roomId = nil;
  _isInitiator = NO;
  _hasReceivedSdp = NO;
  _messageQueue = [NSMutableArray array];
//  _peerConnection = nil;
  self.state = kARDAppClientStateDisconnected;
}
- (void)sendText:(NSNotification *)notification{
    if ([notification.userInfo[@"private"] boolValue]) {
        NSString *targetId = notification.userInfo[@"target"];
        NSString *msg = notification.userInfo[@"msg"];
        [self.webSocket send:[GxpMsgProducer textMsgSenderName:self.userId senderId:self.userId TargetId:targetId text:msg]];
    }else{
        [self.webSocket send:[GxpMsgProducer textMsgSenderName:self.userId senderId:self.userId TargetId:nil text:notification.userInfo[@"msg"]]];

    }
}

- (void)pubMicOn:(NSNotification *)notification{
    if (!_turnOn) {
        [AlertHelper alertWithText:@"请先开启视频"];
        return;
    }

    [self micVideoOn];
    //申请上麦后 从用户列表中删除，添加到麦序列表中
    
    [[GxpUserManager sharedInstance].userList enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:_userId]) {
            [[GxpUserManager sharedInstance].userList removeObject:obj];
            [[GxpUserManager sharedInstance].miclist addObject:obj];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
        }
    }];
}

- (void)privatePubMicOn:(NSNotification *)notification{
    if (!_turnOn) {
        [AlertHelper alertWithText:@"请先开启视频"];
        return;
    }
    
    [self privateMicVideoOn];
    //申请上麦后 从用户列表中删除，添加到麦序列表中
    
    [[GxpUserManager sharedInstance].userList enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:_userId]) {
            [[GxpUserManager sharedInstance].userList removeObject:obj];
            [[GxpUserManager sharedInstance].miclist addObject:obj];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
        }
    }];

}

- (void)privateMicVideoOn{
    [self.webSocket send:[GxpMsgProducer privateMicVideoOnSenderName:self.userId senderId:self.userId]];
}

- (void)micVideoOn{
//    _shangMai = YES;
    [self.webSocket send:[GxpMsgProducer publicMicVideoOnSenderName:self.userId senderId:self.userId]];
}

- (void)micVideoDown{
    if (_shangMai) {
//        _shangMai = NO;//不再处于上麦状态
        NSLog(@"上麦为假");
        [self.webSocket send:[GxpMsgProducer publicMicVideoDownSenderName:self.userId senderId:self.userId]];
        //移除流
        [_peers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RTCPeerConnection *peer = (RTCPeerConnection *)obj;
            NSLog(@"移除流 %@",_mediaStream);
            [peer removeStream:_mediaStream];
        }];
//        _mediaStream = nil;//释放后重新添加
        _mediaStream = [self createLocalMediaStream];
        //添加流
        [_peers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RTCPeerConnection *peer = (RTCPeerConnection *)obj;
            
            [peer addStream:_mediaStream];
        }];


    }
}
#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    signalingStateChanged:(RTCSignalingState)stateChanged {
  NSLog(@"Signaling state changed: %d", stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {

    if (_secondOffer) {
        NSLog(@"和%@的上麦完成了哦",_shangMaiUsers[0]);
        
        [_shangMaiUsers removeObjectAtIndex:0];
        
        if(_shangMaiUsers.count > 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(adminCheckAgreeOnUsers) withObject:nil afterDelay:2];
            });
            
        }else{
            //TODO: delay to set it to false
            _secondOffer = NO;
        }
    }//以上处理多人上麦的情况
    
    
    if (!_endOfferWithSomeOnePubMicOn) {
        if (_pubMicOnUsers.count > 0) {
            [_pubMicOnUsers removeObjectAtIndex:0];
        }
    }
    if ([_sendToId isEqualToString:[GxpUserManager sharedInstance].adminId]) {
        NSLog(@"和房主的offer结束了");
        _endOfferWithAdmin = YES;
    }
    NSLog(@"正在公聊的 %@",_pubMicOnUsers);
    if (_dealWithPreLoginsAsUser) {
        if (_users.count > 0) {
            [_users removeObjectAtIndex:0];
        }else{
            _dealWithPreLoginsAsUser = NO;
        }
    }

    if (_shangMai && _users.count > 0) {
        NSLog(@"有需要处理的之前登陆的人");
        _dealWithPreLoginsAsUser =  YES;
    }
    
      dispatch_async(dispatch_get_main_queue(), ^{
      [self performSelector:@selector(userCheckPubMicOnUsers) withObject:nil afterDelay:4];//作为用户和房主的信令结束后需检查是否有人在公聊
    NSLog(@"Received %lu video tracks and %lu audio tracks",
        (unsigned long)stream.videoTracks.count,
        (unsigned long)stream.audioTracks.count);
    if (stream.videoTracks.count) {
        
      RTCVideoTrack *videoTrack = stream.videoTracks[0];
        videoTrack.belong = _sendToId;
        NSLog(@"收到 %@ 的视频流--------",videoTrack.belong);
        __block NSUInteger index = -1;
        [_remoteVideoTracks enumerateObjectsUsingBlock:^(RTCVideoTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.belong isEqualToString:_sendToId]) {
                [_remoteVideoTracks removeObject:obj];
                index = idx;
            }
        }];
        if (index != -1) {
            [_remoteVideoTracks insertObject:videoTrack atIndex:index];
        }else{
            [_remoteVideoTracks addObject:videoTrack];
        }
        NSLog(@"remotevideotracks %@",_remoteVideoTracks);
      [_delegate appClient:self didReceiveRemoteVideoTracks:[_remoteVideoTracks copy] isAdmin:_isAdmin];
        [_delegate appClient:self didReceiveLocalVideoTrack:[_mediaStream.videoTracks firstObject] isAdmin:_isAdmin];
      if (_isSpeakerEnabled) [self enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.
        
    }
  });
}
- (void)adminCheckAgreeOnUsers{
    _sendToId = _shangMaiUsers[0];
    [self startSignalingIfReady];
}
//登陆时先检查是否有人正在公聊 然后根据自己是否上麦再算处理
- (void)userCheckPubMicOnUsers{
    _endOfferWithSomeOnePubMicOn = YES;//开始此offer的时候置为NO
    if (_pubMicOnUsers.count) {
        NSLog(@"_pubMicOnUsers %@",_pubMicOnUsers);
        _sendToId = [_pubMicOnUsers firstObject][@"sender_ID"];
        NSLog(@"开始和 %@",_sendToId);
        [self handleOthersPubMicOn:[_pubMicOnUsers firstObject]];
    }else{
        NSLog(@"userCheckPubMicOnUsersFailed");
        if (_shangMai && _dealWithPreLoginsAsUser) {
            [self handlePreLoginsWhenPubOn];
        }
    }
}
////作为用户登陆时
//- (void)userCheckPreLogins{
//    
//}
/*
 if (![_remoteVideoTracks containsObject:videoTrack]) {
 [_remoteVideoTracks addObject:videoTrack];
 }
remotevideotracks (
                   "<RTCVideoTrack: 0x170479540>",
                   "<RTCVideoTrack: 0x17006dc80>"
                   )

remotevideotracks (
                   "<RTCVideoTrack: 0x170479540>"
                   )
*/
- (void)peerConnection:(RTCPeerConnection *)peerConnection
        removedStream:(RTCMediaStream *)stream {
  NSLog(@"Stream was removed.");
}

- (void)peerConnectionOnRenegotiationNeeded:
    (RTCPeerConnection *)peerConnection {
    
//    if (_renegotiation) {
//        [peerConnection createOfferWithDelegate:self constraints:[self defaultOfferConstraints]];
//        _renegotiation = NO;
//    }
  NSLog(@"WARNING: Renegotiation needed but unimplemented.");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceConnectionChanged:(RTCICEConnectionState)newState {
  NSLog(@"ICE state changed: %d", newState);
    if (newState == RTCICEConnectionConnected) {
        NSLog(@"建立连接");
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self performSelector:@selector(checkLogins) withObject:nil afterDelay:2];
        });
    }
    
    if (newState == RTCICEConnectionCompleted) {
        _onceCompelete = YES;
        NSLog(@"连接完成");
        if (_isAdmin || _shangMai) {
            if (_shangMaiUsers.count == 0 || _pubMicOnUsers.count == 0) {
                [self checkLogins];
            }
        }
    }
}
//1.我已登陆但是未开启视频  2.我登陆的时候之前已经有让你登陆了
- (void)checkLogins{
    if (_shangMai || _isAdmin) {//处理登入事件 _dealwith login
    NSLog(@" checkLogins logins = %@",_logIns);
        if (_logIns.count > 0) {
            NSLog(@"还有没处理的登入者");
            _dealWithLogIn = YES;
            [self handleLogInUsers:[_logIns firstObject]];
            [_logIns removeObjectAtIndex:0];
        }else{
            _dealWithLogIn = NO;
        }
    }
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceGatheringChanged:(RTCICEGatheringState)newState {
    if (newState == 2) {
        _getAllCandidates = YES;
    }else{
        if (_getAllCandidates) {
            _getAllCandidates = NO;
        }
    }
    
  NSLog(@"ICE gathering state changed: %d", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
//    if (!_getAllCandidates) {
//        if (![_candidates containsObject:candidate]) {
//            [_candidates addObject:candidate];
//        }
//    }
    
    if (!_onceCompelete) {
//        [self sendCandidate:candidate];;
        [_candidates addObject:candidate];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      if (![_log.text containsString:@"ICE"]) {
          _log.text = [NSString stringWithFormat:@"%@\n%@发送ICE",_log.text,_clientId];
      }
  });
}

- (void)sendCandidate:(RTCICECandidate *)candidate{
    _log.textColor = [UIColor blueColor];//暗示发送candidate
    OrderedDictionary *dict;
    if (_secondOffer) {//如果处于上麦的情况的话
        NSString *sendto = [_shangMaiUsers firstObject];
        NSLog(@"发送给 candidate - %@",sendto);
        OrderedDictionary *candidateDict = [OrderedDictionary dictionaryWithObjectsAndKeys:candidate.sdp,@"candidate", candidate.sdpMid,@"sdpMid",@(candidate.sdpMLineIndex),@"sdpMLineIndex",nil];
        dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_ice_candidate",@"event",_clientId,@"sender_ID",sendto,@"target_ID",@{@"candidate": candidateDict},@"data", nil];
//        NSLog(@"dict = %@",dict);
    }else{
        NSLog(@"发送给 candidate + %@",_sendToId);
        OrderedDictionary *candidateDict = [OrderedDictionary dictionaryWithObjectsAndKeys:candidate.sdp,@"candidate", candidate.sdpMid,@"sdpMid",@(candidate.sdpMLineIndex),@"sdpMLineIndex",nil];
        dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_ice_candidate",@"event",_clientId,@"sender_ID",_sendToId,@"target_ID",@{@"candidate": candidateDict},@"data", nil];
    }
    
    NSString  *str = [self dictionaryToJson:dict];
    [self.webSocket send:str];
//    NSLog(@"发送 candidate 给 %@ %@",dict[@"target_ID"],str);
}

- (void)sendSignal:(RTCSessionDescription *)sdp{
    if ([sdp.type isEqualToString:@"offer"]) {
        if (_isAdmin) {
            NSString *msg;
            if (_secondOffer) {
                NSString *sendto = [_shangMaiUsers firstObject];
                if (!sendto) {
                    return;
                }else{
                    _sendToId = sendto;
                }
                msg = [GxpMsgProducer offerFrom:_clientId to:sendto sdp:sdp agreePubMicOn:_secondOffer];
            }else{
                msg = [GxpMsgProducer offerFrom:_clientId to:_sendToId sdp:sdp agreePubMicOn:_secondOffer];
                NSLog(@"普通offer信息---------- %@",msg);
            }
            [self.webSocket send:msg];
            _log.text = [NSString stringWithFormat:@"%@\n%@发送offer给%@",_log.text, _clientId,_sendToId];
            NSLog(@"%@ send offer to %@",_clientId, _sendToId);
        }else{
            NSString *event = @"_offer_video";
            OrderedDictionary *dataDict = [OrderedDictionary dictionaryWithObjectsAndKeys:sdp.type,@"type",sdp.description,@"sdp", nil];
            OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:event,@"event",_clientId,@"sender_ID",_sendToId,@"target_ID",@{@"sdp":dataDict},@"data", nil];
            
            
            NSString *msg = [self dictionaryToJson:dict];
            //        NSLog(@"send offer = %@ ----------- ",msg);
            [self.webSocket send:msg];
            _log.text = [NSString stringWithFormat:@"%@\n%@发送offer给%@",_log.text, _clientId,_sendToId];
            NSLog(@"因为公聊上麦 %@ send offer to %@",_clientId, _sendToId);
        }
        
    }else if ([sdp.type isEqualToString:@"answer"]){
        NSLog(@"%@ send answer to %@",_clientId, _sendToId);
        _log.text = [NSString stringWithFormat:@"%@\n%@发送answer给%@",_log.text, _clientId,_sendToId];
        OrderedDictionary *dataDict = [OrderedDictionary dictionaryWithObjectsAndKeys:sdp.type,@"type",sdp.description,@"sdp", nil];
        OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_answer",@"event",_clientId,@"sender_ID",_sendToId,@"target_ID",@{@"sdp":dataDict},@"data", nil];
        NSString *strTo = [self dictionaryToJson:dict];
        [self.webSocket send:strTo];
    }
}
#pragma mark - RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didCreateSessionDescription:(RTCSessionDescription *)sdp
                          error:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      NSLog(@"Failed to create session description. Error: %@ %@", error,sdp.type);
      [self disconnect];
//      NSDictionary *userInfo = @{
//        NSLocalizedDescriptionKey: @"Failed to create session description.",
//      };
//      NSError *sdpError =
//          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
//                                     code:kARDAppClientErrorCreateSDP
//                                 userInfo:userInfo];
//      [_delegate appClient:self didError:sdpError];
      return;
    }
      NSLog(@"%@ set local description",_clientId);
      
    [[self findLastConnection] setLocalDescriptionWithDelegate:self
                                  sessionDescription:sdp];
//    ARDSessionDescriptionMessage *message =
//        [[ARDSessionDescriptionMessage alloc] initWithDescription:sdp];
      [self sendSignal:sdp];//发送信令
  });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didSetSessionDescriptionWithError:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      NSLog(@"Failed to set session description. Error: %@", error);
      [self disconnect];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to set session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorSetSDP
                                 userInfo:userInfo];
      [_delegate appClient:self didError:sdpError];
      return;
    }
    // If we're answering and we've just set the remote offer we need to create
    // an answer and set the local description.

  });
}

#pragma mark - Private

- (BOOL)isRegisteredWithRoomServer {
  return _clientId.length;
}

- (void)startSignalingIfReady {

    [_peers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RTCPeerConnection *peer = (RTCPeerConnection *)obj;
//        NSLog(@"connect to %@",peer.belong);
        if ([peer.belong isEqualToString:_sendToId]) {
            NSLog(@"找到了之前的连接 %@，现在删除掉",peer.belong);
            [peer removeStream:_mediaStream];
            [_peers removeObject:peer];
        }
    }];//如果之前有这个连接就删掉
  // Create peer connection.
  RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    
  RTCPeerConnection *peerConnection = [_factory peerConnectionWithICEServers:_iceServers
                                               constraints:constraints
                                                  delegate:self];
    peerConnection.belong = _sendToId;
    
    if (_mediaStream) {
        if (_shangMai || _isAdmin) {//如果是房主或者申请上麦的话则添加视频流
            [peerConnection addStream:_mediaStream];
        }
    }else{
        NSLog(@"kaishi xin ling kong _mediaStream");
        _mediaStream = [self createLocalMediaStream];
        if (_shangMai || _isAdmin) {//如果是房主或者申请上麦的话则添加视频流
            [peerConnection addStream:_mediaStream];
        }
    }
    NSLog(@"peerconnection = %@",peerConnection);
    [_peers addObject:peerConnection];
    if (!_isAdmin) {//如果不是房主
        NSLog(@"%@ wait for offer 上麦%@",_clientId,_shangMai?@"yes":@"no");
        if (_shangMai) {
            NSLog(@"因为公聊上麦了故发送 offer");
            [self sendOffer];
        }
//        if (_askForVideo) {
//            NSLog(@"因为有人要和我视频所以发送 offer");
//            [self sendOffer];
//        }
    }else{//房主发送offer
        [self sendOffer];
        NSLog(@"房主发送offer");
    }
    
}
- (void)reactToOffer{
    [_peers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RTCPeerConnection *peer = (RTCPeerConnection *)obj;
        //        NSLog(@"connect to %@",peer.belong);
        if ([peer.belong isEqualToString:_sendToId]) {
            NSLog(@"找到了之前的连接，现在删除掉");
//            [peer removeStream:_mediaStream];
            [_peers removeObject:peer];
        }
    }];//如果之前有这个连接就删掉
    // Create peer connection.
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    
    RTCPeerConnection *peerConnection = [_factory peerConnectionWithICEServers:_iceServers
                                                                   constraints:constraints
                                                                      delegate:self];
    peerConnection.belong = _sendToId;

    if (!_mediaStream) {
        _mediaStream = [self createLocalMediaStream];
    }
    if (_shangMai || _isAdmin || _privateMai) {//如果是房主或者申请上麦的话则添加视频流 (申请上麦包括 私聊 和 公聊)
        NSLog(@"添加流");
        [peerConnection addStream:_mediaStream];
    }
    [_peers addObject:peerConnection];
}
//找到最新活跃的peer_connection websocket open之后就有了
- (RTCPeerConnection *)findLastConnection{
    return [_peers lastObject];
}
- (void)createDataChannel{
//    RTCDataChannelInit *datainit = [[RTCDataChannelInit alloc] init];
//    datainit.isOrdered = YES;
//    _rtcChannel = [_peerConnection createDataChannelWithLabel:@"sender" config:datainit];
//    _rtcChannel.delegate = self;
}
// Called when the data channel state has changed.
- (void)channelDidChangeState:(RTCDataChannel*)channel{
    NSLog(@"did change state %d",channel.state);
    if (channel.state == 1) {
        _open = YES;
    }
}
// hasAdmin 1 是房主
// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer{
    _log.backgroundColor = [UIColor greenColor];
    NSLog(@"did receive msg %@",[[NSString alloc]initWithData:buffer.data encoding:NSUTF8StringEncoding]);
}
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    dispatch_async(dispatch_get_main_queue(), ^{
        _log.text = [NSString stringWithFormat:@"%@\n open data channel",_log.text];
        _log.backgroundColor = [UIColor purpleColor];
    });
    
    _remoteChannel = dataChannel;
    _remoteChannel.delegate = self;
    NSLog(@"open data channel %@",_clientId);
}
- (void)sendOffer {
    RTCPeerConnection *peer = [self findLastConnection];
    
  [peer createOfferWithDelegate:self
                               constraints:[self defaultOfferConstraints]];
}

- (RTCVideoTrack *)createLocalVideoTrack {
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
    // TODO(tkchin): local video capture for OSX. See
    // https://code.google.com/p/webrtc/issues/detail?id=3417.

    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE

    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the front camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"12" source:videoSource];
#endif
    return localVideoTrack;
}

- (RTCMediaStream *)createLocalMediaStream {
    NSLog(@"create media stream-----------------");//if (_turnOn && (_isAdmin || _shangMai || _privateMai))
    if (_turnOn) {
        RTCMediaStream* localStream = [_factory mediaStreamWithLabel:@"erqe"];
        
        
        RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
        if (localVideoTrack) {
//            if (_shangMai||_isAdmin || _privateMai) {
            
                [localStream addVideoTrack:localVideoTrack];//仅在是房主的时候 流中才添加视频
//            }
            [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack isAdmin:_isAdmin];
        }else {
            NSLog(@"创建视频失败");
        }
        RTCAudioTrack *audioTrack = [_factory audioTrackWithID:@"jljljlj"];
        
        
        NSLog(@"create audioTrack --------- %@",audioTrack);
        [localStream addAudioTrack:audioTrack];
//        if (_isSpeakerEnabled) [self enableSpeaker];
        NSLog(@"创建出来的stdream %@",localStream);
        return localStream;
    }else{
        return nil;
    }
    
}

- (void)requestTURNServersWithURL:(NSURL *)requestURL
    completionHandler:(void (^)(NSArray *turnServers))completionHandler {
  NSParameterAssert([requestURL absoluteString].length);
  NSMutableURLRequest *request =
      [NSMutableURLRequest requestWithURL:requestURL];
  // We need to set origin because TURN provider whitelists requests based on
  // origin.
  [request addValue:@"Mozilla/5.0" forHTTPHeaderField:@"user-agent"];
  [request addValue:self.serverHostUrl forHTTPHeaderField:@"origin"];
  [NSURLConnection sendAsyncRequest:request
                  completionHandler:^(NSURLResponse *response,
                                      NSData *data,
                                      NSError *error) {
    NSArray *turnServers = [NSArray array];
    if (error) {
      NSLog(@"Unable to get TURN server.");
      completionHandler(turnServers);
      return;
    }
    NSDictionary *dict = [NSDictionary dictionaryWithJSONData:data];
    turnServers = [RTCICEServer serversFromCEODJSONDictionary:dict];
    completionHandler(turnServers);
  }];
}

//wss://v.jiashizhan.com:8553
#pragma mark - Room server methods
- (void)registerWithUsername:(NSString *)name{
    _peers = [NSMutableArray new];
    _adminId = @"3";
    _userId = name;
    
    [GxpUserManager sharedInstance].adminId = _adminId;
    [GxpUserManager sharedInstance].selfId = _userId;
    
    _log = [[UILabel alloc]initWithFrame:CGRectMake(100, 64, 200, 300)];
    _log.numberOfLines = 0;
    _log.backgroundColor = [UIColor clearColor];
    _log.textColor = [UIColor whiteColor];
    [[UIApplication sharedApplication].keyWindow addSubview:_log];
//    ws://192.168.0.100:8888/Conference/websocket/' + roomid + '/' + userid + '/' + password + '/' + username + '/' + adminid + '/' + roomname + '/' + state
//    ws://192.168.0.112:8080/dbt/websocket my pc
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ws://192.168.0.107:8080/Conference/websocket/3/%@/3/%@/%@/3/conn",_userId, name,_adminId]]]];
    [GxpUserManager sharedInstance].adminId = @"3";//设置房主id
    
    [GxpUserManager sharedInstance].selfId = _userId;
    [GxpUserManager sharedInstance].selfName = _userId;
    self.webSocket.delegate = self;
    self.clientId = name;
    if ([name isEqualToString:_adminId]) {
        self.isAdmin = YES;
    }else{
        self.isAdmin = NO;
    }
    [self.webSocket open];
    
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
//    [self startSignalingIfReady];
    GxpUser *user = [GxpUser new];
    user.userId = _userId;
    if (_isAdmin) {//如果是作为房主登陆的话
        
        [[GxpUserManager sharedInstance].miclist addObject:user];
    }else{
        [[GxpUserManager sharedInstance].userList addObject:user];
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:@"miclist" object:self];
    NSLog(@"Websocket Connected");
    [NSTimer scheduledTimerWithTimeInterval:23 target:self selector:@selector(ping) userInfo:nil repeats:YES];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSDictionary *dict = [NSDictionary dictionaryWithJSONString:message];
    
    NSLog(@"~~````````~~~~~~~~%@", dict);
    if ([dict[@"event"] isEqualToString:@"_offer_start_media"]) {//1.设置远端描述 2.创建一个answer回复对方
        _allVideos++;
        [GxpUserManager sharedInstance].allVideos = _allVideos;
        _endOfferWithAdmin = NO;
        
        _sendToId = dict[@"sender_ID"];
        NSLog(@"%@ received offer from %@",_clientId, _sendToId);
        _log.text = [NSString stringWithFormat:@"%@\n%@收到offer", _log.text, _clientId];
        NSString *sdp = dict[@"data"][@"sdp"][@"sdp"];
        RTCSessionDescription *sessionDes = [[RTCSessionDescription alloc]initWithType:@"offer" sdp:sdp];
        NSLog(@"set remote des");
        
        [self reactToOffer];
        
        RTCPeerConnection *peerConnection = [self findLastConnection];
        if (sessionDes) {
            [peerConnection setRemoteDescriptionWithDelegate:self
                                           sessionDescription:sessionDes];
            [self performSelector:@selector(sendAllCandidates) withObject:nil afterDelay:2];
        }
        
        RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        [peerConnection createAnswerWithDelegate:self
                                      constraints:constraints];
        
    }else if ([dict[@"event"] isEqualToString:@"_answer"]){
        RTCPeerConnection *peerConnection = [self findLastConnection];
        NSString *sdp = dict[@"data"][@"sdp"][@"sdp"];
        NSString *type = dict[@"data"][@"sdp"][@"type"];
        NSLog(@"%@ received answer from %@",_clientId, _sendToId);
        _log.text = [NSString stringWithFormat:@"%@\n%@收到answer", _log.text, _clientId];
        RTCSessionDescription *sessionDes = [[RTCSessionDescription alloc]initWithType:type sdp:sdp];
        [peerConnection setRemoteDescriptionWithDelegate:self
                                       sessionDescription:sessionDes];
        [self performSelector:@selector(sendAllCandidates) withObject:nil afterDelay:2];
        
    }else if([dict[@"event"] isEqualToString:@"_ice_candidate"]){
        RTCPeerConnection *peerConnection = [self findLastConnection];
        NSDictionary *candidateDict = dict[@"data"][@"candidate"];
    NSString *mid = candidateDict[@"sdpMid"];
    
    NSNumber *indexNum = candidateDict[@"sdpMLineIndex"];
    NSInteger index = [indexNum integerValue];
    
    NSString *sdp = candidateDict[@"candidate"];
    
    RTCICECandidate *candidate = [[RTCICECandidate alloc]initWithMid:mid index:index sdp:sdp];
    NSLog(@"%@ received candidate from %@ %@",_clientId, _sendToId, candidate);
    [peerConnection addICECandidate:candidate];
        if (![_log.text containsString:@"收到ICE"]) {
            _log.text = [NSString stringWithFormat:@"%@\n%@收到ICE",_log.text,_clientId];
        }
        
    _log.textColor = [UIColor blueColor];//按时收到candidate
    }else if ([dict[@"event"] isEqualToString:@"_login"]){
        NSLog(@"有人登陆-------------");
        GxpUser *user = [GxpUser new];
        user.userId = dict[@"sender_ID"];
        if ([user.userId isEqualToString:[GxpUserManager sharedInstance].adminId]) {
            [[GxpUserManager sharedInstance].miclist addObject:user];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"miclist" object:@"logIn" userInfo:@{@"userId":dict[@"sender_ID"]}];
        }else{
            [[GxpUserManager sharedInstance].userList addObject:user];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"someonlogin" object:@"logIn" userInfo:@{@"userId":dict[@"sender_ID"]}];
        }
        
        if (_isAdmin||_shangMai) {
            if (!self.turnOn) {
                [AlertHelper alertWithText:@"您还没有开启视频"];
                __block BOOL preContain = NO;
                [_logIns enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:user.userId]) {
                        preContain = YES;
                    }
                }];
                if (!preContain) {
                    [_logIns addObject:user];//先存放起来，等开启视频后再做处理
                }
                
            }else{
//                if (_endOfferWithAdmin && _endOfferWithSomeOnePubMicOn)
                if (_shangMaiUsers.count == 0 && _pubMicOnUsers.count == 0) {
                    NSLog(@"直接出来登陆事件");
                    if (!_isAdmin) {
                        if (_endOfferWithAdmin && _shangMai && !_dealWithPreLoginsAsUser) {
                            _sendToId = dict[@"sender_ID"];
                            [self startSignalingIfReady];
                        }else{
                            __block BOOL preContain = NO;
                            [_logIns enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj.userId isEqualToString:user.userId]) {
                                    preContain = YES;
                                }
                            }];
                            if (!preContain) {
                                NSLog(@"我在忙，登陆者先存起来");
                                [_logIns addObject:user];//先存放起来，等开启视频后再做处理
                            }

                        }
                    }else{
                        if (_endOfferWithSomeOnePubMicOn) {
                            _sendToId = dict[@"sender_ID"];
                            [self startSignalingIfReady];
                        }else{
                            __block BOOL preContain = NO;
                            [_logIns enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj.userId isEqualToString:user.userId]) {
                                    preContain = YES;
                                }
                            }];
                            if (!preContain) {
                                NSLog(@"我在忙，登陆者先存起来");
                                [_logIns addObject:user];//先存放起来，等开启视频后再做处理
                            }

                        }
                    }
                }else{
                    __block BOOL preContain = NO;
                    [_logIns enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.userId isEqualToString:user.userId]) {
                            preContain = YES;
                        }
                    }];
                    if (!preContain) {
                        NSLog(@"我在忙，登陆者先存起来");
                        [_logIns addObject:user];//先存放起来，等开启视频后再做处理
                    }

                }
                
            }
        }
    }else if ([dict[@"event"] isEqualToString:@"_mic_video_on"]){
        NSLog(@"收到申请上麦的消息 不做任何信令处理 立马将其添加到麦序列表中");
        NSString *senderTo = dict[@"sender_ID"];
        [[GxpUserManager sharedInstance].userList enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userId isEqualToString:senderTo]) {
                [[GxpUserManager sharedInstance].userList removeObject:obj];
                [[GxpUserManager sharedInstance].miclist addObject:obj];
            }
            [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
        }];
//            [self startSignalingIfReady];
    }else if([dict[@"event"] isEqualToString:@"_offer_agree_video"]){//收到同意上麦
        _users = [[NSMutableArray alloc]initWithArray:[GxpUserManager sharedInstance].allUsers];
        
        //TODO: 空闲时处理
            NSLog(@"上麦为真");
            _endOfferWithAdmin = NO;
            _shangMai = YES;
            _sendToId = dict[@"sender_ID"];
        NSLog(@"%@ received offer from %@",_clientId, _sendToId);
        _log.text = [NSString stringWithFormat:@"%@\n%@收到offer", _log.text, _clientId];
        NSString *sdp = dict[@"data"][@"sdp"][@"sdp"];
        RTCSessionDescription *sessionDes = [[RTCSessionDescription alloc]initWithType:@"offer" sdp:sdp];
        NSLog(@"set remote des");
        
        [self reactToOffer];
        
        RTCPeerConnection *peerConnection = [self findLastConnection];
        if (sessionDes) {
            [peerConnection setRemoteDescriptionWithDelegate:self
                                          sessionDescription:sessionDes];
        }
        
        [self performSelector:@selector(sendAllCandidates) withObject:nil afterDelay:2];

        RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        [peerConnection createAnswerWithDelegate:self
                                     constraints:constraints];
        

    }else if ([dict[@"event"] isEqualToString:@"_mic_video_down"]){
        [GxpUserManager sharedInstance].forbided = YES;
        _sendToId = dict[@"sender_ID"];
        [[GxpUserManager sharedInstance].onMicVideo enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEqualToString:_sendToId]) {
                [[GxpUserManager sharedInstance].onMicVideo removeObject:obj];
            }
        }];
        [[GxpUserManager sharedInstance].miclist enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userId isEqualToString:_sendToId]) {
                NSLog(@"麦序表中删除，添加到用户表");
                [[GxpUserManager sharedInstance].userList addObject:obj];
                [[GxpUserManager sharedInstance].miclist removeObject:obj];
                [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
            }
        }];
        [_remoteVideoTracks enumerateObjectsUsingBlock:^(RTCVideoTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RTCVideoTrack *video = (RTCVideoTrack *)obj;
            if ([video.belong isEqualToString:_sendToId]) {
                _allVideos--;
                [GxpUserManager sharedInstance].allVideos = _allVideos;
                NSLog(@"删除 %@ 的视频",video.belong);
                [_remoteVideoTracks removeObject:video];
            }
            [self.delegate appClient:self didReceiveRemoteVideoTracks:_remoteVideoTracks isAdmin:_isAdmin];
            [_delegate appClient:self didReceiveLocalVideoTrack:[_mediaStream.videoTracks firstObject] isAdmin:_isAdmin];
        }];
    }else if([dict[@"data"][@"message"] isEqualToString:@"用户下线"]){
        [[GxpUserManager sharedInstance] removeUser:dict[@"sender_ID"]];
        [_peers enumerateObjectsUsingBlock:^(RTCPeerConnection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.belong isEqualToString:dict[@"sender_ID"]]) {
//                [obj removeStream:_mediaStream];
                [_peers removeObject:obj];
            }
        }];
    }else if ([dict[@"data"][@"client_IDs"] count]){//自己登陆时的已经登陆的人
        [dict[@"data"][@"client_IDs"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //client_ids 中是 除了自己之外的所有已经登陆的用户 包括房主
            GxpUser *user = [GxpUser new];
            user.userId = obj;
            if (![user.userId isEqualToString:[GxpUserManager sharedInstance].adminId]) {
                __block BOOL preContain = NO;
                [_logIns enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.userId isEqualToString:user.userId]) {
                        preContain = YES;
                    }
                }];
                if (!preContain) {
                    [_logIns addObject:user];
                }
                NSLog(@"client_IDs logins = %@",_logIns);
            }
            if ([obj isEqualToString:[GxpUserManager sharedInstance].adminId]) {
                [[GxpUserManager sharedInstance].miclist addObject:user];
            }else{
                [[GxpUserManager sharedInstance].userList addObject:user];
            }
        }];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
    }else if ([dict[@"event"] isEqualToString:@"_textChat_message"]){
        GxpMsg *msg = [GxpMsg new];
        msg.msg = [self getMsgText: dict[@"data"][@"message"]];
        msg.isCome = YES;
        [[GxpMsgManager sharedInstance].msgs addObject:msg];
    }else if ([dict[@"event"] isEqualToString:@"_offer_video"]){//有用户在视频，发送offer(房主先接通)
//        _sendToId = dict[@"sender_ID"];
        NSLog(@"有人公聊上麦 发来offer");
        
        _allVideos++;
        [GxpUserManager sharedInstance].allVideos = _allVideos;
        [self performSelector:@selector(startOfferVideo:) withObject:dict afterDelay:2];
        
    }else if ([dict[@"event"] isEqualToString:@"_forbidOnMic"]){
        NSLog(@"被禁麦");
        [GxpUserManager sharedInstance].forbided = YES;
        [[GxpUserManager sharedInstance].miclist enumerateObjectsUsingBlock:^(GxpUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userId isEqualToString:_userId]) {
                NSLog(@"麦序表中删除，添加到用户表");
                [[GxpUserManager sharedInstance].userList addObject:obj];
                [[GxpUserManager sharedInstance].miclist removeObject:obj];
                [[NSNotificationCenter defaultCenter]postNotificationName:@"all" object:self];
            }
        }];

        [_peers enumerateObjectsUsingBlock:^(RTCPeerConnection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj removeStream:_mediaStream];
                NSLog(@"删除流");
        }];
        _allVideos--;
        [GxpUserManager sharedInstance].allVideos = _allVideos;
        [self.delegate appClient:self didReceiveRemoteVideoTracks:[_remoteVideoTracks copy] isAdmin:_isAdmin];
        [self.delegate appClient:self didReceiveLocalVideoTrack:nil isAdmin:NO];
        [self.webSocket send:[GxpMsgProducer publicMicVideoDownSenderName:_userId senderId:_userId]];//响应房主的下麦
    }else if([dict[@"event"] isEqualToString:@"_offer_agree_video_private"]){//收到同意私聊上麦
        NSLog(@"收到同意私聊上麦的消息");
        _privateMai = YES;
        _sendToId = dict[@"sender_ID"];
        NSLog(@"%@ received offer from %@",_clientId, _sendToId);
        _log.text = [NSString stringWithFormat:@"%@\n%@收到offer", _log.text, _clientId];
        NSString *sdp = dict[@"data"][@"sdp"][@"sdp"];
        RTCSessionDescription *sessionDes = [[RTCSessionDescription alloc]initWithType:@"offer" sdp:sdp];
        NSLog(@"set remote des");
        
        [self reactToOffer];
        
        RTCPeerConnection *peerConnection = [self findLastConnection];
        if (sessionDes) {
            [peerConnection setRemoteDescriptionWithDelegate:self
                                          sessionDescription:sessionDes];
        }
        
        [self performSelector:@selector(sendAllCandidates) withObject:nil afterDelay:2];
        
        RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        [peerConnection createAnswerWithDelegate:self
                                     constraints:constraints];
    }
//    NSLog(@"receive %@",[self dictionaryToJson:dict]);
}

- (void)startOfferVideo:(NSDictionary *)dict{
    if (_endOfferWithAdmin && _endOfferWithSomeOnePubMicOn) {
        NSLog(@"开始offer video");
        _endOfferWithSomeOnePubMicOn = NO;
        _sendToId = dict[@"sender_ID"];
        [self handleOthersPubMicOn:dict];
    }else{
        [_pubMicOnUsers addObject:dict];
        NSLog(@"_pubMicOnUsers %@",_pubMicOnUsers);
    }
}

//{"room_NAME":"3","data":{"client_NAMEs":["3"],"room_AMIC":[],"client_IDs":["3"],"room_VMIC":[],"room_PMIC":[]},"target_ID":"4","event":"_canOffer","sender_NAME":"4","sender_ID":"服务器"}
- (void)handlePreLoginsWhenPubOn{
    if (_users.count > 0) {
        NSLog(@"处理自己上麦时之前已经有人登陆");
        GxpUser *user = _users[0];
        _sendToId = user.userId;
        [self startSignalingIfReady];
    }else{
        _dealWithPreLoginsAsUser = NO;
    }
    
}
- (void)handleLogInUsers:(GxpUser *)user{
//    _dealWithLogIn = YES;
    _sendToId = user.userId;
    NSLog(@"处理登入者 %@",_sendToId);
    [self startSignalingIfReady];
}
- (void)handleOthersPubMicOn:(NSDictionary *)dict{
    
//    _log.text = [NSString stringWithFormat:@"%@\n%@收到offer", _log.text, _clientId];
    NSString *sdp = dict[@"data"][@"sdp"][@"sdp"];
    RTCSessionDescription *sessionDes = [[RTCSessionDescription alloc]initWithType:@"offer" sdp:sdp];
    NSLog(@"set remote des");
    
    [self reactToOffer];
    
    RTCPeerConnection *peerConnection = [self findLastConnection];
    if (sessionDes) {
        [peerConnection setRemoteDescriptionWithDelegate:self
                                      sessionDescription:sessionDes];
    }
    [self performSelector:@selector(sendAllCandidates) withObject:nil afterDelay:2];
    
    RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
    [peerConnection createAnswerWithDelegate:self
                                 constraints:constraints];
}
//<p>djlsjas<br\/><\/p>
- (NSString *)getMsgText:(NSString *)msg{
    NSString *returnStr;
    if ([msg containsString:@"<p>"]) {
        returnStr = [[msg componentsSeparatedByString:@"<br"] firstObject];
        returnStr = [[returnStr componentsSeparatedByString:@"<p>"] lastObject];
    }else{
        returnStr = msg;
    }
    
    return returnStr;
}
- (void)sendAllCandidates{
//    if (_onceCompelete) {
        NSLog(@"send candidate %ld------------",(unsigned long)_candidates.count);
        for (RTCICECandidate *candidate in _candidates) {
            [self sendCandidate:candidate];
        }
//    }
    
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    _log.backgroundColor = [UIColor redColor];
    NSLog(@"Closed Reason:%@",reason);
    self.webSocket = nil;
}

- (void)ping {
    NSString *hasAdmin;
    if(_isAdmin){
        hasAdmin = @"1";
    }else{
        hasAdmin = @"0";
    }
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_ping",@"event",_clientId,@"sender_ID",@"服务器",@"target_ID",hasAdmin,@"hasAdmin",@{@"message": [NSString stringWithFormat:@"%@--ping",_clientId]},@"data", nil];
    NSString *str = [self dictionaryToJson:dict];
    [self.webSocket send:str];
    if (_open) {
        NSData *data = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
        RTCDataBuffer *buffer = [[RTCDataBuffer alloc]initWithData:data isBinary:YES];
        
        if([_rtcChannel sendData:buffer]){
            _log.backgroundColor = [UIColor whiteColor];
            NSLog(@"发送消息");
        }
    }
}

- (NSString*)dictionaryToJson:(NSDictionary *)dic

{
    
    //    [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *STR = DICTTOSTR(dic);
    return STR;
    //    return nil;
}

- (void)registerWithRoomServerForRoomId:(NSString *)roomId
    completionHandler:(void (^)(ARDRegisterResponse *))completionHandler {
  NSString *urlString =
      [NSString stringWithFormat:kARDRoomServerRegisterFormat, self.serverHostUrl, roomId];
  NSURL *roomURL = [NSURL URLWithString:urlString];
  NSLog(@"Registering with room server.");
  __weak ARDAppClient *weakSelf = self;

  [NSURLConnection sendAsyncPostToURL:roomURL
                             withData:nil
                    completionHandler:^(BOOL succeeded, NSData *data) {
    ARDAppClient *strongSelf = weakSelf;
    if (!succeeded) {
      NSError *error = [self roomServerNetworkError];
      [strongSelf.delegate appClient:strongSelf didError:error];
      completionHandler(nil);
      return;
    }
    ARDRegisterResponse *response =
        [ARDRegisterResponse responseFromJSONData:data];
    completionHandler(response);
  }];
}

- (void)sendSignalingMessageToRoomServer:(ARDSignalingMessage *)message
    completionHandler:(void (^)(ARDMessageResponse *))completionHandler {
  NSData *data = [message JSONData];
  NSString *urlString =
      [NSString stringWithFormat:
          kARDRoomServerMessageFormat, self.serverHostUrl, _roomId, _clientId];
  NSURL *url = [NSURL URLWithString:urlString];
  NSLog(@"C->RS POST: %@", message);
  __weak ARDAppClient *weakSelf = self;
  [NSURLConnection sendAsyncPostToURL:url
                             withData:data
                    completionHandler:^(BOOL succeeded, NSData *data) {
    ARDAppClient *strongSelf = weakSelf;
    if (!succeeded) {
      NSError *error = [self roomServerNetworkError];
      [strongSelf.delegate appClient:strongSelf didError:error];
      return;
    }
    ARDMessageResponse *response =
        [ARDMessageResponse responseFromJSONData:data];
    NSError *error = nil;
    switch (response.result) {
      case kARDMessageResultTypeSuccess:
        break;
      case kARDMessageResultTypeUnknown:
        error =
            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                       code:kARDAppClientErrorUnknown
                                   userInfo:@{
          NSLocalizedDescriptionKey: @"Unknown error.",
        }];
      case kARDMessageResultTypeInvalidClient:
        error =
            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                       code:kARDAppClientErrorInvalidClient
                                   userInfo:@{
          NSLocalizedDescriptionKey: @"Invalid client.",
        }];
        break;
      case kARDMessageResultTypeInvalidRoom:
        error =
            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                       code:kARDAppClientErrorInvalidRoom
                                   userInfo:@{
          NSLocalizedDescriptionKey: @"Invalid room.",
        }];
        break;
    };
    if (error) {
      [strongSelf.delegate appClient:strongSelf didError:error];
    }
    if (completionHandler) {
      completionHandler(response);
    }
  }];
}

- (void)unregisterWithRoomServer {
  NSString *urlString =
      [NSString stringWithFormat:kARDRoomServerByeFormat, self.serverHostUrl, _roomId, _clientId];
  NSURL *url = [NSURL URLWithString:urlString];
  NSLog(@"C->RS: BYE");
    //Make sure to do a POST
    [NSURLConnection sendAsyncPostToURL:url withData:nil completionHandler:^(BOOL succeeded, NSData *data) {
        if (succeeded) {
            NSLog(@"Unregistered from room server.");
        } else {
            NSLog(@"Failed to unregister from room server.");
        }
    }];
}

- (NSError *)roomServerNetworkError {
  NSError *error =
      [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                 code:kARDAppClientErrorNetwork
                             userInfo:@{
    NSLocalizedDescriptionKey: @"Room server network error",
  }];
  return error;
}

#pragma mark - Collider methods



- (void)sendSignalingMessageToCollider:(ARDSignalingMessage *)message {
//  NSData *data = [message JSONData];
//  [_channel sendData:data];
}

#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:nil];
  return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
  return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
  NSArray *mandatoryConstraints = @[
      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"],
  ];
    
    NSArray *optionals = @[
//                           [[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"],
                           [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"],
                           ];
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:mandatoryConstraints
                   optionalConstraints:optionals];
  return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
  NSArray *optionalConstraints = @[
      [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"],
//      [[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"]
  ];
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:optionalConstraints];
  return constraints;
}

- (NSMutableArray *)defaultSTUNServer {
//  NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];

    NSMutableArray *servers = [NSMutableArray new];
    RTCICEServer *server1 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"stun:turn.jiashizhan.com"] username:@"" password:@""];
    RTCICEServer *server2 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:turn.jiashizhan.com"] username:@"zhimakai" password:@"zhimakai888"];
    RTCICEServer *server3 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"stun:webrtcweb.com:7788"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server4 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:7788"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server5 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turns:webrtcweb.com:7788"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server6 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:8877"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server7 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turns:webrtcweb.com:8877"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server8 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"stun:webrtcweb.com:4455"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server9 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:4455"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server10 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:3344"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server11 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:4433"] username:@"muazkh" password:@"muazkh"];
    RTCICEServer *server12 = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:@"turn:webrtcweb.com:5544?transport=tcp"] username:@"muazkh" password:@"muazkh"];
    [servers addObjectsFromArray:@[server1, server2, server3, server4, server5, server6, server7, server8, server9, server10, server11, server12]];
    return servers;
}

#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream *localStream = peerConnection.localStreams[0];
    self.defaultAudioTrack = localStream.audioTracks[0];
    
    [self.defaultAudioTrack setEnabled:NO];
    
    NSLog(@"audio track %@",self.defaultAudioTrack);
    if([localStream removeAudioTrack:localStream.audioTracks[0]]){
        NSLog(@"删除音频成功");
    }
//    [self disableSpeaker];
    [peerConnection removeStream:localStream];
    NSLog(@"localstreams 2 = %@",peerConnection.localStreams);

    [peerConnection addStream:localStream];
    NSLog(@"localstreams 3 = %@",peerConnection.localStreams);
}
- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream* localStream = peerConnection.localStreams[0];
    [self.defaultAudioTrack setEnabled:YES];
    [localStream addAudioTrack:self.defaultAudioTrack];
    [peerConnection removeStream:localStream];
    [peerConnection addStream:localStream];
    
    if (_isSpeakerEnabled) [self enableSpeaker];
}

#pragma mark - Video mute/unmute
- (void)muteVideoIn {
    NSLog(@"video muted");
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream *localStream = peerConnection.localStreams[0];
    self.defaultVideoTrack = localStream.videoTracks[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    [peerConnection removeStream:localStream];
    [peerConnection addStream:localStream];
}
- (void)unmuteVideoIn {
    NSLog(@"video unmuted");
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream* localStream = peerConnection.localStreams[0];
    [localStream addVideoTrack:self.defaultVideoTrack];
    [peerConnection removeStream:localStream];
    [peerConnection addStream:localStream];
}

#pragma mark - swap camera
- (RTCVideoTrack *)createLocalVideoTrackBackCamera {
    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    //AVCaptureDevicePositionFront
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the back camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}
- (void)swapCameraToFront{
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream *localStream = peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];

    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack isAdmin:_isAdmin];
    }
    [peerConnection removeStream:localStream];
    [peerConnection addStream:localStream];
}
- (void)swapCameraToBack{
    RTCPeerConnection *peerConnection = [self findLastConnection];
    RTCMediaStream *localStream = peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrackBackCamera];
    
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack isAdmin:_isAdmin];
    }
    [peerConnection removeStream:localStream];
    [peerConnection addStream:localStream];
}

#pragma mark - enable/disable speaker

- (void)enableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    _isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    _isSpeakerEnabled = NO;
}
@end
