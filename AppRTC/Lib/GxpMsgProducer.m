//
//  GxpMsgProducer.m
//  Pods
//
//  Created by gaoxiupei on 2017/6/1.
//
//

#import "GxpMsgProducer.h"
#import "OrderedDictionary.h"


@implementation GxpMsgProducer
+ (NSString *)textMsgSenderName:(NSString *)senderName senderId:(NSString *)senderId TargetId:(NSString *)targetId text:(NSString *)textmsg{
    if (targetId == nil) {
        targetId = @"所有人";
    }
    if (textmsg == nil) {
        textmsg = @"我也不知道说啥好呢";
    }
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_textChat_message",@"event",senderId,@"sender_ID",targetId,@"target_ID",senderName,@"sender_NAME",@{@"message":textmsg},@"data", nil];
    NSLog(@"txtmsg %@",DICTTOSTR(dict));
    return DICTTOSTR(dict);
}

+ (NSString *)publicMicVideoOnSenderName:(NSString *)senderName senderId:(NSString *)senderId{
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_mic_video_on",@"event",senderId,@"sender_ID",@"所有人",@"target_ID",senderName,@"sender_NAME",@"公开",@"media_TYPE",@{@"message":@"申请视频上麦"},@"data", nil];
    return DICTTOSTR(dict);
}

+ (NSString *)privateMicVideoOnSenderName:(NSString *)senderName senderId:(NSString *)senderId{
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_mic_video_on",@"event",senderId,@"sender_ID",@"所有人",@"target_ID",senderName,@"sender_NAME",@"私聊",@"media_TYPE",@{@"message":@"申请视频上麦"},@"data", nil];
    return DICTTOSTR(dict);
}
+ (NSString *)publicMicVideoDownSenderName:(NSString *)senderName senderId:(NSString *)senderId{
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_mic_video_down",@"event",senderId,@"sender_ID",@"所有人",@"target_ID",senderName,@"sender_NAME",@{@"message":@"申请视频下麦"},@"data", nil];
    return DICTTOSTR(dict);
}

+(NSString *)offerFrom:(NSString *)senderId to:(NSString *)sendToId sdp:(RTCSessionDescription *)sdp agreePubMicOn:(BOOL)pubMicOn{
    NSString *event;
    if (pubMicOn) {
        event = @"_offer_agree_video";
    }else{
        event = @"_offer_start_media";
    }
    OrderedDictionary *dataDict = [OrderedDictionary dictionaryWithObjectsAndKeys:sdp.type,@"type",sdp.description,@"sdp", nil];
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:event,@"event",senderId,@"sender_ID",sendToId,@"target_ID",@{@"sdp":dataDict},@"data", nil];
    return DICTTOSTR(dict);
}
+ (NSString *)senderId:(NSString *)senderId forbidId:(NSString *)whoId{
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_forbidOnMic",@"event",senderId,@"sender_ID",whoId,@"target_ID",@{@"message":@"你已经被禁止发言和上麦"},@"data", nil];
    return DICTTOSTR(dict);

}

+ (NSString *)pubOfflineSenderId:(NSString *)senderId senderName:(NSString *)senderName onMic:(BOOL)mic{
    NSString *media_type;
    if (mic) {
        media_type = @"公开";
    }else{
        media_type = @"无";
    }
    OrderedDictionary *dict = [OrderedDictionary dictionaryWithObjectsAndKeys:@"_offline",@"event",senderId,@"sender_ID",@"server",@"target_ID",senderName,@"sender_NAME",media_type,@"media_TYPE",@{@"message":@"正常退出会议室"},@"data", nil];
    return DICTTOSTR(dict);

}
@end
