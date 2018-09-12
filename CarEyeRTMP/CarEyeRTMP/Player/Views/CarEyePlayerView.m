//
//  CarEyePlayerView.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/7/28.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "CarEyePlayerView.h"
#import "ControlBar.h"
#import "Masonry.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "PathTool.h"
#import "RecordEntity.h"
@interface CarEyePlayerView()<ControlBarDelegate>
@property (strong, nonatomic) id<IJKMediaPlayback> player;
@property (strong, nonatomic) ControlBar *ctrBar;
@property (strong, nonatomic) UIActivityIndicatorView *activity;
@property (strong, nonatomic) UIButton *addPlayerBtn;
@property (nonatomic, copy) NSString * url;
@property (strong, nonatomic) dispatch_queue_t record_queue;


@end

@implementation CarEyePlayerView
@synthesize frameBeforeFull = _frameBeforeFull;

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}
- (void)initSubviews {
    self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.hidesWhenStopped = YES;
    [self addSubview:self.activity];
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    self.addPlayerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addPlayerBtn.frame = CGRectZero;
    [self addSubview:self.addPlayerBtn];
    [self.addPlayerBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self.addPlayerBtn addTarget:self action:@selector(addUrlAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.addPlayerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
    self.ctrBar = [[NSBundle mainBundle] loadNibNamed:@"ControlBar" owner:self options:nil].firstObject;
    self.ctrBar.delegate = self;
    [self addSubview:self.ctrBar];
//    self.ctrBar.frame = CGRectMake(0, self.frame.size.height-20, self.frame.size.width, 20);
    [self.ctrBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.bottom.equalTo(self);
    }];
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _frameBeforeFull = frame;
        [self initSubviews];
        self.record_queue = dispatch_queue_create("cn.car-eye.record", DISPATCH_QUEUE_SERIAL);

    }
    return self;
}
- (CGRect)frameBeforeFull {
    return _frameBeforeFull;
}
- (void)playerUrl:(NSString *)url {
    if(self.player) {
        [self removeMovieNotificationObserversForPlayer:self.player];
        self.player = nil;
    }
    self.addPlayerBtn.hidden = YES;
    [self.activity startAnimating];
    self.player = [self createPlayerWithUrl:url];
    [self addSubview:self.player.view];
    [self bringSubviewToFront:self.ctrBar];
    [self.player prepareToPlay];
    [self installMovieNotificationObserversForPlayer:self.player];
    [self.player play];
}
- (void)stop {
    if ([self.player isPlaying]) {
        [self removeMovieNotificationObserversForPlayer:self.player];
        [self.player stop];
        self.player = nil;
    }
    [self.activity stopAnimating];
    self.addPlayerBtn.hidden = NO;
}
- (void)pause {
    if ([self.player isPlaying]) {
        [self.player pause];
    }
    NSLog(@"============%@",self.ctrBar);
}
- (void)dealloc {
    if (self.player) {
        [self removeMovieNotificationObserversForPlayer:self.player];
    }
}
- (id<IJKMediaPlayback>)createPlayerWithUrl:(NSString *)url {
    self.url = url;
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"]; // 启用硬解码
    [options setFormatOptionValue:@"1" forKey:@"start-on-prepared"]; // 准备时立即播放
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter"];
    //    ijkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "http-detect-range-support", 0);
    //    ijkMediaPlayer.setOption(1, "flush_packets", 1L);
    //    ijkMediaPlayer.setOption(4, "packet-buffering", 0L);
    //    [options setPlayerOptionIntValue:0 forKey:@""];
    //    [options setPlayerOptionIntValue:0 forKey:@"http"];
    //    [options setPlayerOptionIntValue:0 forKey:@""];
    //    [options setPlayerOptionIntValue:48 forKey:@""];
    //    [options setPlayerOptionIntValue:8 forKey:@""];
    //    [options setPlayerOptionIntValue:100L forKey:@""];
    //    [options setPlayerOptionIntValue:10240L forKey:@""];
    //    [options setPlayerOptionIntValue:1L forKey:@""];
    //    [options setPlayerOptionIntValue:10 forKey:@"max-buffer-size"];
    //    [options setFormatOptionIntValue:10 forKey:@"rtbufsize"];
    //    [options setFormatOptionIntValue:2000000 forKey:@"analyzeduration"];
    //    [options setFormatOptionValue:@"nobuffer" forKey:@"fflags"];
    //    [options setFormatOptionIntValue:4096 forKey:@"probsize"];
    [options setPlayerOptionIntValue:1 forKey:@"framedrop"];
    IJKFFMoviePlayerController *player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:url withOptions:options];
    player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    player.view.frame = self.bounds;
    player.scalingMode = IJKMPMovieScalingModeAspectFit;
    [player setPlaybackVolume:0];
    player.shouldAutoplay = YES;
    
    return player;
}
- (void)addUrlAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(carEyePlayerView:didClickAdd:)]) {
        [self.delegate carEyePlayerView:self didClickAdd:sender];
    }
}
#pragma mark ====================== ControlBarDelegate  ===================
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toPause:(BOOL)isPausing{
    if ([self.player isPlaying] && isPausing) {
        if (ctlBar.recordBtn.isSelected) {
            [self.player stopRecord];
            ctlBar.recordBtn.selected = NO;
        }
        if(ctlBar.voiceBtn.isSelected) {
            ctlBar.recordBtn.selected = NO;
        }
        [self.player stop];
    }
    else {
        [self playerUrl:self.url];
    }
}

- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toFullScreen:(BOOL)isFulling{
    if ([self.delegate respondsToSelector:@selector(carEyePlayerView:didClickToFull:)]) {
        [self.delegate carEyePlayerView:self didClickToFull:isFulling];
    }
}
- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toOpenVoice:(BOOL)isToOpen{
    if (isToOpen) {
        [self.player setPlaybackVolume:1];
    }else {
        [self.player setPlaybackVolume:0];
    }
}

- (void)controlBar:(ControlBar *)ctlBar didClickBtn:(UIButton *)btn toRecord:(BOOL)isToRecord{
    if (![self.player isPlaying]) {
        btn.selected = NO;
        return;
    }
    if (isToRecord) {
        
        dispatch_async(self.record_queue, ^{
            RecordEntity *entity = [PathTool entityWithUrl:self.url];
            [self.player startRecordInPath:entity.videoPath];
            IJKFFMoviePlayerController *player = (IJKFFMoviePlayerController *)self.player;
            [UIImagePNGRepresentation([player snapshot]) writeToFile:entity.snapshotPath atomically:YES];
        });
    }else {
//        dispatch_async(self.record_queue, ^{
            [self.player stopRecord];
//        });
    }
    
}
#pragma mark ====================== notification  ===================
#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationObserversForPlayer:(id<IJKMediaPlayback>)player
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:player];
}


/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObserversForPlayer:(id<IJKMediaPlayback>)player
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:player];
}


- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    id<IJKMediaPlayback> player = notification.object;
    IJKMPMovieLoadState loadState = player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    id<IJKMediaPlayback> player = notification.object;
    
    switch (player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped 停止了", (int)player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing 播放中", (int)player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused,已经暂停", (int)player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted 中断了", (int)player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking 快进回退中", (int)player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)player.playbackState);
            break;
        }
    }
}

@end
