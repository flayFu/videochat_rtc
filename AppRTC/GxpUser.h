//
//  GxpUser.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/3.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum USERSTATE{
    USERSTATEDEFAULT,//默认状态 未上麦
    USERSTATEPUBMICON,//已经上麦
}USERSTATE;
@interface GxpUser : NSObject
//@property(nonatomic, copy)NSString *userName;
@property(nonatomic, copy)NSString *userId;
@property(nonatomic, assign)USERSTATE state;
@end
