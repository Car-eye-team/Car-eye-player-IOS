//
//  ViewController.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/7/19.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "CarEyePlayerView.h"
#import "RecordListViewController.h"

#define k_width [UIScreen mainScreen].bounds.size.width
#define k_height [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<CarEyePlayerViewDelegate>
@property (retain, nonatomic) id<IJKMediaPlayback> player0;
@property (retain, nonatomic) id<IJKMediaPlayback> player1;
@property (retain, nonatomic) id<IJKMediaPlayback> player2;
@property (retain, nonatomic) id<IJKMediaPlayback> player3;
@property (strong, nonatomic) NSMutableArray *players;
@property (strong, nonatomic) CarEyePlayerView *playerView0;
@property (strong, nonatomic) CarEyePlayerView *playerView1;
@property (strong, nonatomic) CarEyePlayerView *playerView2;
@property (strong, nonatomic) CarEyePlayerView *playerView3;

@property (nonatomic, copy) NSString * currentUrl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat leading = 0; // 左右边距
    CGFloat midMargin = 2;// 两个视图中间间隔
    CGFloat topMargin = 2; // 与上面视图间隔
    CGFloat itemWidth = (k_width - midMargin - (2*leading))*0.5;
    CGFloat itemHeight = itemWidth;
    
//    self.player0 = [self createAPlyerInFrame:CGRectMake(leading, topMargin, itemWidth, itemHeight) url:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
//    [self.view addSubview:self.player0.view];
//    self.player1 = [self createAPlyerInFrame:CGRectMake(itemWidth+leading+midMargin, topMargin, itemWidth, itemHeight) url:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
//    [self.view addSubview:self.player1.view];
//    self.player2 = [self createAPlyerInFrame:CGRectMake(leading, topMargin+itemHeight, itemWidth, itemHeight) url:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
//    [self.view addSubview:self.player2.view];
//    self.player3 = [self createAPlyerInFrame:CGRectMake(itemWidth+leading+midMargin, topMargin+itemHeight, itemWidth, itemHeight) url:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
//    [self.view addSubview:self.player3.view];
    self.playerView0 = [self createPlayerViewWithFrame:CGRectMake(leading, topMargin, itemWidth, itemHeight)];
    self.playerView1 = [self createPlayerViewWithFrame:CGRectMake(itemWidth+leading+midMargin, topMargin, itemWidth, itemHeight)];
    self.playerView2 = [self createPlayerViewWithFrame:CGRectMake(leading, topMargin*2+itemHeight, itemWidth, itemHeight)];
    self.playerView3 = [self createPlayerViewWithFrame:CGRectMake(itemWidth+leading+midMargin, topMargin*2+itemHeight, itemWidth, itemHeight)];
    [self.view addSubview:self.playerView0];
    [self.view addSubview:self.playerView1];
    [self.view addSubview:self.playerView2];
    [self.view addSubview:self.playerView3];
    

    self.edgesForExtendedLayout = UIRectEdgeNone;
}
- (CarEyePlayerView *)createPlayerViewWithFrame:(CGRect)frame {
    CarEyePlayerView *view = [[CarEyePlayerView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor blackColor];
    view.delegate = self;
    return view;
}
#pragma mark ====================== CarEyePlayerViewDelegate  ===================
- (void)carEyePlayerView:(CarEyePlayerView *)view didClickAdd:(UIButton *)btn {
    UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"请输入播放地址" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(&*self) wself = self;
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *tf = alertCtr.textFields.firstObject;
        NSString* url = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        wself.currentUrl = url;
        [view playerUrl:url];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertCtr addAction:action];
    [alertCtr addAction:cancel];
    [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"rtmp://";
        textField.text = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
        wself.currentUrl = textField.text;
    }];
    [self presentViewController:alertCtr animated:YES completion:nil];
    
}

- (void)carEyePlayerView:(CarEyePlayerView *)view didClickToFull:(BOOL)goFulling {
    if (goFulling) {
        AppDelegate *appd = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appd.allowRotate = YES;
        [UIDevice switchOrientation:UIInterfaceOrientationLandscapeRight];
        [self enterFullscreen:view];
    }else{
        AppDelegate *appd = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appd.allowRotate = NO;
        [UIDevice switchOrientation:UIInterfaceOrientationPortrait];

        [self exitFullscreen:view];
    }
}

#pragma mark ====================== actions  ===================

- (IBAction)historyAction:(UIBarButtonItem *)sender {
    RecordListViewController *vc = [[RecordListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark ====================== fullScreen  ===================

- (void)enterFullscreen:(CarEyePlayerView *)playerView {
    
    if (playerView.state != CarEyePlayViewStateSmall) {
        return;
    }
    
    playerView.state = CarEyePlayViewStateAnimating;
    /*
     * PlayView移到window上
     */
    CGRect rectInWindow = [playerView convertRect:playerView.bounds toView:[UIApplication sharedApplication].keyWindow];
    [playerView removeFromSuperview];
    playerView.frame = rectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:playerView];
    
    /*
     * 执行动画
     */
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    [UIView animateWithDuration:0.5 animations:^{
//        playerView.transform = CGAffineTransformMakeRotation(M_PI_2);
        playerView.bounds = screenBounds;
        playerView.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));
    } completion:^(BOOL finished) {
        playerView.state = CarEyePlayViewStateFullscreen;
    }];
    
    [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
}

- (void)exitFullscreen:(CarEyePlayerView *)playerView {
    
    if (playerView.state != CarEyePlayViewStateFullscreen) {
        return;
    }
    
    playerView.state = CarEyePlayViewStateAnimating;
    
    CGRect frame = [self.view convertRect:playerView.frameBeforeFull toView:[UIApplication sharedApplication].keyWindow];
    [UIView animateWithDuration:0.5 animations:^{
//        playerView.transform = CGAffineTransformIdentity;
        playerView.frame = frame;
    } completion:^(BOOL finished) {
        /*
         * PlayView回到小屏位置
         */
        [playerView removeFromSuperview];
        playerView.frame = playerView.frameBeforeFull;
        [self.view addSubview:playerView];
        playerView.state = CarEyePlayViewStateSmall;
    }];
    
//    [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.player0 prepareToPlay];
//    [self.player1 prepareToPlay];
//    [self.player2 prepareToPlay];
//    [self.player3 prepareToPlay];
    
    
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
//    [self.player shutdown];
//    [self removeMovieNotificationObservers];
}
#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
