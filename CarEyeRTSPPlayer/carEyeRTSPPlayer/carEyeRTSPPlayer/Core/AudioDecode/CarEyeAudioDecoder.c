//
//  CarEyeAudioDecoder.c
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/5/18.
//  Copyright © 2018年 car-eye. All rights reserved.
//
#include "AACDecoder.h"
#include "CarEyeRTSPClientAPI.h"
#include "CarEyeAudioDecoder.h"
#include "g711.h"

#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"

CarEyeAudioHandle* CarEyeAudioDecoder(int code, int sample_rate, int channels, int sample_bit) {
    CarEyeAudioHandle *pHandle = malloc(sizeof(CarEyeAudioHandle));
    pHandle->code = code;
    pHandle->pContext = 0;
    if (code == CAREYE_ACODE_AAC || code == CAREYE_ACODE_G726) {
        av_register_all();
        pHandle->pContext = aac_decoder_create(code, sample_rate, channels, sample_bit);
        if(NULL == pHandle->pContext) {
            free(pHandle);
            return NULL;
        }
    }
    
    return pHandle;
}

CarEyeAudioHandle *CarEyeAudioDecoderCreate(CarEye_RtspFrameInfo info) {
    CarEyeAudioHandle *handle = malloc(sizeof(CarEyeAudioHandle));
    handle->code = info.codec;
    handle->pContext = 0;
    if (info.codec == CAREYE_ACODE_AAC || info.codec == CAREYE_ACODE_G726) {
        av_register_all();
        handle->pContext = aac_decoder_create(info.codec, info.sample_rate, info.channels, 16);
        if (NULL == handle->pContext) {
            free(handle);
            return NULL;
        }
    }
    return handle;
}
int CarEyeAudioDecode(CarEyeAudioHandle* pHandle, unsigned char* buffer, int offset, int length, unsigned char* pcm_buffer, int* pcm_length) {
    int err = 0;
    if (pHandle->code == CAREYE_ACODE_AAC || pHandle->code == CAREYE_ACODE_G726) {
        err = aac_decode_frame(pHandle->pContext, (unsigned char *)(buffer + offset),length, (unsigned char *)pcm_buffer, (unsigned int*)pcm_length);
    } else if (pHandle->code == CAREYE_ACODE_G711U) {
        short *pOut = (short *)(pcm_buffer);
        unsigned char *pIn = (unsigned char *)(buffer + offset);
        for (int m=0; m<length; m++){
            pOut[m] = ulaw2linear(pIn[m]);
        }
        *pcm_length = length*2;
    } else if (pHandle->code == CAREYE_ACODE_G711A) {
        short *pOut = (short *)(pcm_buffer);
        unsigned char *pIn = (unsigned char *)(buffer + offset);
        for (int m=0; m<length; m++){
            pOut[m] = alaw2linear(pIn[m]);
        }
        *pcm_length = length*2;
    }
    
    return err;
}

void CarEyeAudioDecodeClose(CarEyeAudioHandle* pHandle) {
    if (pHandle->code == CAREYE_ACODE_AAC || pHandle->code == CAREYE_ACODE_G726){
        aac_decode_close(pHandle->pContext);
    }
    
    free(pHandle);
}
