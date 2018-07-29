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
- (void)controlBar:(ControlBar *)ctlBar didClickToPause:(BOOL)isPausing;
- (void)controlBar:(ControlBar *)ctlBar didClickToOpenVoice:(BOOL)isToOpen;
- (void)controlBar:(ControlBar *)ctlBar didClickToRecord:(BOOL)isToRecord;
- (void)controlBar:(ControlBar *)ctlBar didClickToFullScreen:(BOOL)isFulling;
@end
@interface ControlBar : UIView
@property (weak, nonatomic) id <ControlBarDelegate> delegate;
@end

