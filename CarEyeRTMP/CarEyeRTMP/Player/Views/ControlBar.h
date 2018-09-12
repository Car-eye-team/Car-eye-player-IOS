//
//  ControlBar.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/7/5.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ControlBar;
@protocol ControlBarDelegate <NSObject>
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toPause:(BOOL)isPausing;
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toOpenVoice:(BOOL)isToOpen;
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toRecord:(BOOL)isToRecord;
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toFullScreen:(BOOL)isFulling;
@end
@interface ControlBar : UIView
@property (weak, nonatomic) id <ControlBarDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *playbtn;
@property (weak, nonatomic) IBOutlet UIButton *voiceBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *fullBtn;

@end

