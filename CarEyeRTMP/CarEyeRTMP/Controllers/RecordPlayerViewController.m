//
//  RecordPlayerViewController.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/28.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "RecordPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface RecordPlayerViewController ()
@property (nonatomic, retain) AVPlayerViewController *playerViewController;

@end

@implementation RecordPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL *url = [NSURL fileURLWithPath:self.path];
    AVPlayer *avPlayer = [AVPlayer playerWithURL:url];
    _playerViewController = [[AVPlayerViewController alloc] init];
    _playerViewController.player = avPlayer;
    _playerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    _playerViewController.showsPlaybackControls = YES;
    _playerViewController.view.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64);
    [self addChildViewController:_playerViewController];
    [self.view addSubview:_playerViewController.view];
    [_playerViewController.player play];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_playerViewController) {
        [_playerViewController.player pause];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
