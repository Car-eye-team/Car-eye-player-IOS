//
//  PlayerView.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ControlBar.h"
typedef NS_ENUM(NSUInteger, PlayViewState) {
    PlayViewStateSmall,
    PlayViewStateAnimating,
    PlayViewStateFullscreen,
};

@interface PlayerView : UIView
@property (assign, nonatomic) BOOL audioPlaying;
@property (strong, nonatomic) ControlBar *ctrBar;
@property (assign, nonatomic) PlayViewState state;
/**
 记录小屏时的parentView
 */
@property (nonatomic, weak) UIView *playViewParentView;

/**
 记录小屏时的frame
 */
@property (nonatomic, assign) CGRect playViewFrame;


- (void)renderWithURL:(NSString *)url;
- (void)stopRender;
@end
