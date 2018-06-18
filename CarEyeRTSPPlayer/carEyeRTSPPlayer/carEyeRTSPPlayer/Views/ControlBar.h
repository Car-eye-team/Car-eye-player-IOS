//
//  ControlBar.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/7/5.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ControlBarDelegate <NSObject>
- (void)didClickToPause:(BOOL)isPausing;
- (void)didClickToFullScreen:(BOOL)isFulling;
@end
@interface ControlBar : UIView
@property (weak, nonatomic) id <ControlBarDelegate> delegate;
@end

