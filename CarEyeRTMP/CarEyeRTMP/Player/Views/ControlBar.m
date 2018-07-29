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
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickToPause:)]) {
        [self.delegate controlBar:self didClickToPause:sender.isSelected];
    }
}
- (IBAction)openVoiceAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if([self.delegate respondsToSelector:@selector(controlBar:didClickToOpenVoice:)]) {
        [self.delegate controlBar:self didClickToOpenVoice:sender.isSelected];
    }

}
- (IBAction)recordingAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickToRecord:)]) {
        [self.delegate controlBar:self didClickToRecord:sender.isSelected];
    }

}

- (IBAction)fullScreenAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(controlBar:didClickToFullScreen:)]) {
        [self.delegate controlBar:self didClickToFullScreen:sender.isSelected];
    }

}

@end
