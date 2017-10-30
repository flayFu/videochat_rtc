//
//  GxpMsgManager.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/9.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface GxpMsgManager : NSObject
+ (instancetype)sharedInstance;
@property(nonatomic, strong)NSMutableArray *msgs;
@end
