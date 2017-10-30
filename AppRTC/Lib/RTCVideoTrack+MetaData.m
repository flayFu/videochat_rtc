//
//  RTCVideoTrack+MetaData.m
//  Pods
//
//  Created by gaoxiupei on 2017/5/24.
//
//

#import "RTCVideoTrack+MetaData.h"
#import <objc/runtime.h>
@implementation RTCVideoTrack (MetaData)
static void *belongKey = "belong";

- (void)setBelong:(NSString *)belong{
    objc_setAssociatedObject(self, belongKey,belong,OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)belong{
    return objc_getAssociatedObject(self, belongKey);
}

@end
