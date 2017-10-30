//
//  InputView.m
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/9.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import "InputView.h"
#import "GxpMsg.h"
#import "GxpMsgManager.h"
#import "AlertHelper.h"
@interface InputView (){
    UITextField *_tf;
    NSString *_target;
}
@end
@implementation InputView
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//- (instancetype)initWithFrame:(CGRect)frame{
//    self = [super initWithFrame:frame];
//    if (self) {
//        UITextField *tf = [[UITextField alloc]initWithFrame:CGRectMake(10, 0, 100, 50)];
//        tf.backgroundColor = [UIColor greenColor];
//        [self addSubview:tf];
//        
//        
//        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.backgroundColor = [UIColor redColor];
//        btn.frame = CGRectMake(CGRectGetMaxX(tf.frame) + 10, 0, 100, 50);
//        [btn addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:btn];
//
//    }
//    return self;
//}
- (IBAction)changeMode:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (!sender.selected) {
        _sendToId = nil;
    }
}
- (IBAction)showUsers:(id)sender {
    if ([self.delegate respondsToSelector:@selector(showUsers)]) {
        [self.delegate showUsers];
    }
}

- (IBAction)sendMsg:(id)sender {
    if (_privateBtn.isSelected) {
        if (_sendToId == nil) {
            [AlertHelper alertWithText:@"请选择你要私聊的人"];
            return;
        }
    }
    [_tf becomeFirstResponder];
    if ([self.delegate respondsToSelector:@selector(xp_inputView:msgToSend:private:to:)]) {
        GxpMsg *msg = [GxpMsg new];
        msg.msg = _msgTf.text;
        msg.isCome = NO;
        [[GxpMsgManager sharedInstance].msgs addObject:msg];
        [self.delegate xp_inputView:self msgToSend:_msgTf.text private:_privateBtn.isSelected to:_sendToId];
    }
}



@end
