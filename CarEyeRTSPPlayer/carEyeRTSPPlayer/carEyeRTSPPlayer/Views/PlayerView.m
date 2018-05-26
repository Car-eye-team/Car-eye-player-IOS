//
//  PlayerView.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "PlayerView.h"
#import "KxMovieGLView.h"
#import "RTSPStreamReader.h"
#import "KxMovieDecoder.h"
#import "CarEyeAudioPlayer.h"
@interface PlayerView()
@property (strong, nonatomic) RTSPStreamReader *reader;
@property (strong, nonatomic) KxMovieGLView *glView;


@end
@implementation PlayerView
{
    NSTimeInterval _tickCorrectionTime; // 时间纠正
    NSTimeInterval _tickCorretionPosition; // 位置纠正
    CGFloat _moviePosition;
    NSUInteger _currentAudioFramePos;
    CGFloat _bufferdDuration;
    NSMutableArray <KxVideoFrame *> *_videoFrames;
    NSMutableArray <KxAudioFrame *> *_audioFrames;
    NSData *_currentAudioFrameSamples;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    self.reader = [[RTSPStreamReader alloc] init];
    self.backgroundColor = [UIColor blackColor];
    _glView = [[KxMovieGLView alloc] initWithFrame:self.bounds];
    [self addSubview:_glView];
    _videoFrames = [NSMutableArray array];
    _audioFrames = [NSMutableArray array];
    __weak PlayerView *weakSelf = self;
    self.reader.succCall = ^{
        NSLog(@"获得frame");
        [weakSelf dealStackTopFrame];
    };
    self.reader.getAVFrameSuccCall = ^(KxMovieFrame *frame) {
        NSLog(@"\n------------------------------\n获得普通帧\n----------------------------\n");
        NSLog(@"%@",frame);
        [weakSelf pushFrame:frame]; // 填充视频
        [weakSelf startAudio];
        // 填充音频
        
    };
    
    
}
- (instancetype)init {
    _tickCorrectionTime = 0;
    _tickCorretionPosition = 0;
    _moviePosition = 0;
    _currentAudioFramePos = 0;
    _bufferdDuration = 0;
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}


- (void)renderWithURL:(NSString *)url {
    if (self.reader) {
        [self.reader stop];
        [self.glView flush];
        self.reader = nil;
    }
    __weak PlayerView *weakSelf = self;
    self.reader = [[RTSPStreamReader alloc] init];
    self.reader.succCall = ^{
        NSLog(@"获得frame");
        [weakSelf dealStackTopFrame];
    };
    self.reader.getAVFrameSuccCall = ^(KxMovieFrame *frame) {
        NSLog(@"\n------------------------------\n获得普通帧\n----------------------------\n");
        NSLog(@"%@",frame);
        [weakSelf pushFrame:frame]; // 填充视频
        [weakSelf startAudio];
        // 填充音频
        
    };
    [self.reader startWithURL:url];
}


#pragma mark - 播放控制

- (void)startAudio {
    self.audioPlaying = YES;
    [CarEyeAudioPlayer sharedInstance].sampleRate = _reader.frameInfo->codec;
    [CarEyeAudioPlayer sharedInstance].channel = _reader.frameInfo->channels;
    [[CarEyeAudioPlayer sharedInstance] play];
    __weak PlayerView *weakSelf = self;
    [CarEyeAudioPlayer sharedInstance].source = self;
    [CarEyeAudioPlayer sharedInstance].outputBlock = ^(SInt16 *outData, UInt32 numFrames, UInt32 numChannels){
        [weakSelf pushAudioData:outData numFrames:numFrames numChannels:numChannels];
    };
}

- (void)stopAudio {
    if ([CarEyeAudioPlayer sharedInstance].source == self) {
        [[CarEyeAudioPlayer sharedInstance] stop];
        [CarEyeAudioPlayer sharedInstance].outputBlock = nil;
    }
    self.audioPlaying = NO;
}



- (void)pushFrame:(KxMovieFrame *)frame {
    if (frame.type == KxMovieFrameTypeVideo) {
        @synchronized(_videoFrames) {
            //        if (self.videoStatus != Rendering) {
            //            [_videoFrames removeAllObjects];
            //            return;
            //        }
            
            [_videoFrames addObject:(KxVideoFrame*)frame];
            _bufferdDuration = frame.position - ((KxVideoFrameRGB *)_videoFrames.firstObject).position;
        }
        
    }else if (frame.type == KxMovieFrameTypeAudio) {
        @synchronized(_audioFrames) {
            if (!self.audioPlaying) {
                [_audioFrames removeAllObjects];
                return;
            }
            
            [_audioFrames addObject:(KxAudioFrame *)frame];
        }
        
    }
}

// 处理栈顶frame，纠偏
- (void)dealStackTopFrame {
    CGFloat duration = 0;
    NSTimeInterval time = 0.01;
    KxVideoFrame *frame = nil;
    @synchronized(_videoFrames) {
        if ([_videoFrames count] > 0) {
            frame = [_videoFrames firstObject];
            [_videoFrames removeObjectAtIndex:0];
        }
    }
    if (frame != nil) {
        duration = [self renderWithFrame:frame];
        NSTimeInterval correction = [self tickCorrection];
        NSTimeInterval interval = MAX(duration + correction, 0.01);
        if (interval >= 0.035) {
            interval = interval / 2;
        }
        
        time = interval;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self dealStackTopFrame];
    });
}

#pragma mark - 处理音频数据

- (void)pushAudioData:(SInt16 *) outData numFrames: (UInt32) numFrames numChannels: (UInt32) numChannels {
    @autoreleasepool {
        while (numFrames > 0) {
            if (_currentAudioFrameSamples == nil) {
                @synchronized(_audioFrames) {
                    NSUInteger count = _audioFrames.count;
                    if (count > 0) {
                        KxAudioFrame *frame = _audioFrames[0];
                        CGFloat differ = _moviePosition - frame.position;
                        
                        [_audioFrames removeObjectAtIndex:0];
                        
                        if (differ > 5 && count > 1) {
                            //                            NSLog(@"audio skip movPos = %.4f audioPos = %.4f", _moviePosition, frame.position);
                            continue;
                        }
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrameSamples = frame.samples;
                    }
                }
            }
            
            if (_currentAudioFrameSamples) {
                const void *bytes = (Byte *)_currentAudioFrameSamples.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrameSamples.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(SInt16);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                if (bytesToCopy < bytesLeft) {
                    _currentAudioFramePos += bytesToCopy;
                } else {
                    _currentAudioFrameSamples = nil;
                }
            } else {
                memset(outData, 0, numFrames * numChannels * sizeof(SInt16));
                break;
            }
        }
    }
}

#pragma mark 渲染到view，并获取到当前帧的持续时间
- (NSTimeInterval )renderWithFrame:(KxVideoFrame *)frame {
    [self.glView render:frame];
    _moviePosition = frame.position;
    return frame.duration;
}

- (NSTimeInterval )tickCorrection {
    if (_moviePosition == 0) {
        return 0;
    }
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (_tickCorrectionTime == 0) {
        _tickCorrectionTime = now;
        _tickCorretionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPos = _moviePosition - _tickCorretionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPos - dTime;
    if (correction > 0) {
        //        NSLog(@"tick correction reset %0.2f", correction);
        correction = 0;
    }
    
    if (_bufferdDuration >= 0.3) {
        //        NSLog(@"bufferdDuration = %f play faster", _bufferdDuration);
        correction = -1;
    }
    
    return correction;
}


@end

