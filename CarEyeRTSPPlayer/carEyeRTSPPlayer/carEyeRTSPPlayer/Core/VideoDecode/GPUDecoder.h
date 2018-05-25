//
// Car eye 车辆管理平台: www.car-eye.cn
// Car eye 开源网址: https://github.com/Car-eye-team
//
//  GPUDecoder.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/15.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KxMovieDecoder.h"
typedef enum :NSUInteger{
    GPUDecoderDecodeTypeH264,
    GPUDecoderDecodeTypeH265
}GPUDecoderDecodeType;

@protocol GPUDecoderDelegate;
@interface GPUDecoder : NSObject
@property (assign, nonatomic) GPUDecoderDecodeType decodeType;
@property (weak, nonatomic) id <GPUDecoderDelegate> delegate;
- (BOOL)decodeVideoWithData:(unsigned char *)dataRef dataLength:(int)length;
- (void)destroy;
@end

@protocol GPUDecoderDelegate <NSObject>
-(void)receivePictureFrame:(KxMovieFrame *)frame; // 通知上层已获取到图像帧
@end
