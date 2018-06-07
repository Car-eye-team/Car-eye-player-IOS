
//
//  RTSPStreamReader.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarEyeRTSPClientAPI.h"
@class KxMovieFrame;
@interface RTSPStreamReader : NSObject
@property (nonatomic, copy) NSString * url;
@property (assign, nonatomic) CarEye_MediaInfo *mediaInfo;


@property (nonatomic, copy) void (^succCall)(void); // 获取到媒体信息后调用
@property (nonatomic, copy) void (^getAVFrameSuccCall)(KxMovieFrame *frame); //获取到解码后的音视频帧后输出
@property (assign, nonatomic) BOOL enableAudio;


- (void)startWithURL:(NSString *)url;
- (void)stop;
//- (CarEye_MediaInfo *)mediaInfo;
@end

