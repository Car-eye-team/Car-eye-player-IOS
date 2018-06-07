//
//  CarEyeAudioDecoder.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/5/18.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#ifndef CarEyeAudioDecoder_h
#define CarEyeAudioDecoder_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    typedef struct _HANDLE_ {
        unsigned int code;
        void *pContext;
    } CarEyeAudioHandle;
    
    // 创建音频解码器
    CarEyeAudioHandle* CarEyeAudioDecoder(int code, int sample_rate, int channels, int sample_bit);
    CarEyeAudioHandle *CarEyeAudioDecoderCreate(CarEye_MediaInfo info);
    
    // 解码一帧音频数据
    int CarEyeAudioDecode(CarEyeAudioHandle* pHandle, unsigned char* buffer, int offset, int length, unsigned char* pcm_buffer, int* pcm_length);
    
    // 关闭音频解码帧
    void CarEyeAudioDecodeClose(CarEyeAudioHandle* pHandle);
    
#ifdef __cplusplus
}
#endif

#endif /* CarEyeAudioDecoder_h */
