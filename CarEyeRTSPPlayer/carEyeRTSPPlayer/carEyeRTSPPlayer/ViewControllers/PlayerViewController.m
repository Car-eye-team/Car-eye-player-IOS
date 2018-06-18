//
//  PlayerViewController.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"
#import "CarEyeRTSPClientAPI.h"
#import "CarEyeAudioPlayer.h"

@interface PlayerViewController ()<ControlBarDelegate>
@property (nonatomic, copy) NSString * currenUrl;


@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CarEye_RtspActivate("6A59754D6A3469576B5A73414D433158714E4C4F6B76464659584E3555477868655756794C6D56345A536C58444661672F704C67523246326157346D516D466962334E68514449774D545A4659584E355247467964326C75564756686257566863336B3D");
    //    [self.playerView renderWithURL:@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov"];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    self.playerView.audioPlaying = YES;
    self.navigationItem.rightBarButtonItem = item;
    self.playerView.ctrBar.delegate = self;
//    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
//    [self.playerView addGestureRecognizer:tapGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)addAction {
    UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"请输入播放地址" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(&*self) wself = self;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *tf = alertCtr.textFields.firstObject;
        NSString* url = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        wself.currenUrl = url;
        [wself.playerView renderWithURL:url];
        [[CarEyeAudioPlayer sharedInstance] activateAudioSession];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertCtr addAction:action];
    [alertCtr addAction:cancel];
    [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"rtsp://";
        textField.text = @"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov";
        wself.currenUrl = textField.text;
    }];
    [self presentViewController:alertCtr animated:YES completion:nil];
}
#pragma mark ====================== ControlBarDelegate  ===================
- (void)didClickToFullScreen:(BOOL)isFulling { // 点击全屏
    if (isFulling) {
        [self enterFullscreen];
    }else{
        [self exitFullscreen];
    }
}
- (void)didClickToPause:(BOOL)isPausing {
    if (isPausing) {
        [self.playerView stopRender];
    }else {
        [self.playerView renderWithURL:self.currenUrl];
    }
}
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.playerView.state == PlayViewStateSmall) {
            [self enterFullscreen];
        }
        else if (self.playerView.state == PlayViewStateFullscreen) {
            [self exitFullscreen];
        }
    }
}


- (void)enterFullscreen {
    
    if (self.playerView.state != PlayViewStateSmall) {
        return;
    }
    
    self.playerView.state = PlayViewStateAnimating;
    
    /*
     * 记录进入全屏前的parentView和frame
     */
    self.playerView.playViewParentView = self.playerView.superview;
    self.playerView.playViewFrame = self.playerView.frame;
    
    /*
     * PlayView移到window上
     */
    CGRect rectInWindow = [self.playerView convertRect:self.playerView.bounds toView:[UIApplication sharedApplication].keyWindow];
    [self.playerView removeFromSuperview];
    self.playerView.frame = rectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:self.playerView];
    
    /*
     * 执行动画
     */
    [UIView animateWithDuration:0.5 animations:^{
        self.playerView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.playerView.bounds = CGRectMake(0, 0, CGRectGetHeight(self.playerView.superview.bounds), CGRectGetWidth(self.playerView.superview.bounds));
        self.playerView.center = CGPointMake(CGRectGetMidX(self.playerView.superview.bounds), CGRectGetMidY(self.playerView.superview.bounds));
    } completion:^(BOOL finished) {
        self.playerView.state = PlayViewStateFullscreen;
    }];
    
    [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
}

- (void)exitFullscreen {
    
    if (self.playerView.state != PlayViewStateFullscreen) {
        return;
    }
    
    self.playerView.state = PlayViewStateAnimating;
    
    CGRect frame = [self.playerView.playViewParentView convertRect:self.playerView.playViewFrame toView:[UIApplication sharedApplication].keyWindow];
    [UIView animateWithDuration:0.5 animations:^{
        self.playerView.transform = CGAffineTransformIdentity;
        self.playerView.frame = frame;
    } completion:^(BOOL finished) {
        /*
         * PlayView回到小屏位置
         */
        [self.playerView removeFromSuperview];
        self.playerView.frame = self.playerView.playViewFrame;
        [self.playerView.playViewParentView addSubview:self.playerView];
        self.playerView.state = PlayViewStateSmall;
    }];
    
    [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:YES];
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end

