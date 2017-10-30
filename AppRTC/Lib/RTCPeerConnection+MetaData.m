//
//  RTCPeerConnection+MetaData.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/5/11.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "RTCPeerConnection+MetaData.h"
#import <objc/runtime.h>
@implementation RTCPeerConnection (MetaData)

static void *belongKey = "belong";

- (void)setBelong:(NSString *)belong{
    objc_setAssociatedObject(self, belongKey,belong,OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)belong{
    return objc_getAssociatedObject(self, belongKey);
}
@end
