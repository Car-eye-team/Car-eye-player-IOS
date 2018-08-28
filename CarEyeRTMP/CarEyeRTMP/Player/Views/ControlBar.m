//
//  ControlBar.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/7/5.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "ControlBar.h"

@implementation ControlBar

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
}
- (IBAction)pauseAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickBtn:toPause:)]) {
        [self.delegate controlBar:self didClickBtn:sender toPause:sender.isSelected];
    }
}
- (IBAction)openVoiceAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if([self.delegate respondsToSelector:@selector(controlBar:didClickBtn:toOpenVoice:)]) {
        [self.delegate controlBar:self didClickBtn:sender toOpenVoice:sender.isSelected];
    }

}
- (IBAction)recordingAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickBtn:toRecord:)]) {
        [self.delegate controlBar:self didClickBtn:sender toRecord:sender.isSelected];
    }

}

- (IBAction)fullScreenAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickBtn:toFullScreen:)]) {
        [self.delegate controlBar:self didClickBtn:sender toFullScreen:sender.isSelected];
    }

}

@end
