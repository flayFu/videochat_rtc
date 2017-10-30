//
//  GxpMsgProducer.h
//  Pods
//
//  Created by gaoxiupei on 2017/6/1.
//
//

#import <Foundation/Foundation.h>
#import <RTCSessionDescription.h>
#define DATATOSTR(DATA) [[NSString alloc] initWithData:DATA encoding:NSUTF8StringEncoding]

#define DICTTOSTR(DICT) DATATOSTR([NSJSONSerialization dataWithJSONObject:DICT options:0 error:nil])

@interface GxpMsgProducer : NSObject

/**
 发送文字消息

 @param senderName 发送者的名字
 @param senderId 发送者的id
 @param targetId 发送给谁 如果没有值 则发送给所有人
 @return 字符串化的消息
 */
+ (NSString *)textMsgSenderName:(NSString *)senderName senderId:(NSString *)senderId TargetId:(NSString *)targetId text:(NSString *)textmsg;

/**
 申请公聊上麦

 @param senderName 谁上麦
 @param senderId 上麦者的id
 @return 字符串化的消息
 */
+ (NSString *)publicMicVideoOnSenderName:(NSString *)senderName senderId:(NSString *)senderId;
+ (NSString *)privateMicVideoOnSenderName:(NSString *)senderName senderId:(NSString *)senderId;

/**
 公聊下麦

 @param senderName 谁下麦
 @param senderId 下麦者的id
 @return 字符串化的消息
 */
+ (NSString *)publicMicVideoDownSenderName:(NSString *)senderName senderId:(NSString *)senderId;

/**
 同意上麦的offer

 @param who 谁同意的
 @param sendToId 同意谁
 @return 字符串化的消息
 */
+ (NSString *)offerFrom:(NSString *)senderId to:(NSString *)sendToId sdp:(RTCSessionDescription *)sdp agreePubMicOn:(BOOL)pubMicOn;

/**
 禁止某人上麦与发消息

 @param senderId 房主id
 @param whoId 禁止谁
 @return 字符串化的消息
 */
+ (NSString *)senderId:(NSString *)senderId forbidId:(NSString *)whoId;
///下线
+ (NSString *)pubOfflineSenderId:(NSString *)senderId senderName:(NSString *)senderName onMic:(BOOL)mic;
@end
