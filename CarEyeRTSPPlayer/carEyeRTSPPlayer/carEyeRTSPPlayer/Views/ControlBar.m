//
//  ControlBar.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/7/5.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "ControlBar.h"

@implementation ControlBar

- (IBAction)pauseAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(didClickToPause:)]) {
        [self.delegate didClickToPause:sender.isSelected];
    }
}

- (IBAction)fullScreenAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(didClickToFullScreen:)]) {
        [self.delegate didClickToFullScreen:sender.isSelected];
    }

}

@end
