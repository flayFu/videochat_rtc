//
//  InputView.h
//  AppRTC
//
//  Created by gaoxiupei on 2017/6/9.
//  Copyright © 2017年 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
@class InputView;

@protocol InputViewDelegate <NSObject>
@optional
- (void)xp_inputView:(InputView *)inputview msgToSend:(NSString *)msg private:(BOOL)privateMsg to:(NSString *)target;
- (void)showUsers;
@end

@interface InputView : UIView
@property(nonatomic, copy)NSString *sendToId;
@property (weak, nonatomic) IBOutlet UITextField *msgTf;
@property (weak, nonatomic) IBOutlet UIButton *privateBtn;
@property(nonatomic, weak)id <InputViewDelegate>delegate;
@end
