//
//  RTCPeerConnection+MetaData.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/5/11.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "RTCPeerConnection.h"

#define RANDOM_STR(LENGTH) [[NSUUID UUID].UUIDString substringToIndex:LENGTH>36?36:LENGTH]

@interface RTCPeerConnection (MetaData)
@property(nonatomic, copy)NSString *belong;
@end
