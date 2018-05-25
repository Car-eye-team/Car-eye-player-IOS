//
// Car eye 车辆管理平台: www.car-eye.cn
// Car eye 开源网址: https://github.com/Car-eye-team
//
//  GPUDecoder.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/15.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "GPUDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "KxMovieDecoder.h"

/*
    每个 NALU 单元 = [start code] + [NALU header] + [NALU payload]
    start code 为 00 00 01 或者 00 00 00 01
    NALU header 为一个字节 分为三部份 = forbidden_zero_bit(1bit) + nal_ref_idc(2bit) + nal_unit_type(5bit)
    例如 sps 的 NALU header 为 0x67 对应二进制 0110 0111 第一位 0 表示不禁止/无错误，第2、3位为 11 = 3，最后5位表示类型 00111 = 7
 
 
*/
typedef enum : int {
    GPUDecoder_NALU_TypeNoDivide = 1, // 非IDR图像中不采用数据划分的片段
    GPUDecoder_NALU_TypeDivideA  = 2, // 非IDR 图像中A类数据划分片段
    GPUDecoder_NALU_TypeDivideB  = 3, // 非IDR 图像中B类数据划分片段
    GPUDecoder_NALU_TypeDivideC  = 4, // 非IDR 图像中C类数据划分片段
    GPUDecoder_NALU_TypeIDR      = 5, // IDR 图像的片
    GPUDecoder_NALU_TypeSEI      = 6, // 补充增强信息
    GPUDecoder_NAUL_TypeSPS      = 7, // sps的开头第一个字节(NALU header)是0x67，NALU header的后5位为7
    GPUDecoder_NAUL_TypePPS      = 8,   // pps 开头的第一个字节是0x68 NALU header后5位为8
    GPUDecoder_NAUL_TypePE       = 9,   // picture delimiter 分界符
    GPUDecoder_NAUL_TypeEOS      = 10,  // end of picture
} GPUDecoder_NALU_Type;

@interface GPUDecoder(){
    CMVideoFormatDescriptionRef formatDescriptionOut;   // 源数据的描述
    VTDecompressionSessionRef decompressSession; // 解码会话
    
    uint8_t *_spsRef;
    uint8_t *_ppsRef;
    
    unsigned char *pInnerData;
    unsigned int innerLen;
}

@end

@implementation GPUDecoder

- (instancetype)init {
    if (self = [super init]) {
        innerLen = 0;
        pInnerData = NULL;
    }
    return self;
}


// 2、回调函数可以完成CGBitmap图像转换成UIImage图像的处理，将图像通过队列发送到Control来进行显示处理
void didDecompress(void *decompressionOutputRefCon,
                   void *sourceFrameRefCon,
                   OSStatus status,
                   VTDecodeInfoFlags infoFlags,
                   CVImageBufferRef imageBuffer,
                   CMTime presentationTimeStamp,
                   CMTime presentationDuration) {
    if (status != noErr || !imageBuffer) {
        NSLog(@"Error decompresssing frame at time: %.3f error: %d infoFlags: %u",
              (float)presentationTimeStamp.value / presentationTimeStamp.timescale,
              (int)status,
              (unsigned int)infoFlags);
        return;
    }
    
    if (status == noErr) {
        if (imageBuffer != NULL) {
            __weak __block GPUDecoder *weakSelf = (__bridge GPUDecoder *)decompressionOutputRefCon;
#if 1
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            
            // 获取图像内部数据
            void *base;
            size_t width, height, bytesPerRow;
            base = CVPixelBufferGetBaseAddress(imageBuffer);
            width = CVPixelBufferGetWidth(imageBuffer);
            height = CVPixelBufferGetHeight(imageBuffer);
            bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            //            size_t dataSize = CVPixelBufferGetDataSize(imageBuffer);
            
            @autoreleasepool {
                KxVideoFrameRGB *frame = [[KxVideoFrameRGB alloc] init];
                frame.width = width;
                frame.height = height;
                frame.linesize = bytesPerRow;
                frame.hasAlpha = YES;
                frame.rgb = [NSData dataWithBytes:base length:bytesPerRow * height];
                frame.duration = 0.04;
                [weakSelf.delegate receivePictureFrame:frame];
            }
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
#else
            [weakSelf.hwDelegate getDecodePixelData:imageBuffer];
#endif
        }
    }
}


/**
 从frame数据获取sps/pps 起始位置和长度

 @param frameDataRef frame数据
 @param frameDataLength frame 数据长度
 @param type GPUDecoder_NALU_Type NALU 类型，7为 sps，8为pps
 @param xpsStart sps/pps 起始位置
 @param xpsLength sps/pps 长度
 */
static inline void read_sps_pps_dataFromData(unsigned char *frameDataRef, int frameDataLength, GPUDecoder_NALU_Type type, int *xpsStart, int *xpsLength) {
    int i;
    int startCodeIndex = -1;
    
    // 0x00 00 00 01四个字节为StartCode，在两个StartCode之间的内容即为一个完整的NALU。
    // 存储的一般形式为: 00 00 00 01 SPS 00 00 00 01 PPS 00 00 00 01 I帧
    for (i = 0; i < frameDataLength - 4; i++) {
        if ((0 == frameDataRef[i]) && (0 == frameDataRef[i + 1]) && (1 == frameDataRef[i + 2]) && (type == (frameDataRef[i + 3] & 0x0F))) {
            startCodeIndex = i;
            break;
        }
    }
    
    if (-1 == startCodeIndex) {
        return;
    }
    
    int pos1 = -1;
    for (i = startCodeIndex + 4; i < frameDataLength - 4; i++) {
        if ((0 == frameDataRef[i]) && (0 == frameDataRef[i + 1]) && (1 == frameDataRef[i + 2])) {
            pos1 = i;
            
            if (frameDataRef[i - 1] == 0) {
                // 00 00 00 01
                pos1--;
            }
            break;
        }
    }
    
    if (-1 == pos1) {
        return;
    }
    
    *xpsStart = startCodeIndex + 3;
    *xpsLength = pos1 - startCodeIndex - 3;
    printf("type = %d xpsLen= %d; outPos = %d, pos1 = %d\n", type, *xpsLength, *xpsStart, pos1);
}
//- (void)read_SPS_PPS_dataWithFrameData:(unsigned char *)frameDataRef length:(int)len {
//
//}

/**
 读取sps pps数据的逻辑(获取sps、pps的起始位置和长度)
 
 @param data        数据
 @param offset      从0开始
 @param length      数据长度
 @param type        7代表sps,8代表pps(0x67是SPS的NAL头，0x68是PPS的NAL头)
 @param outPos      sps、pps的起始位置
 @param xpsLen      sps、pps的长度
 */
static inline void getXps(unsigned char *data, int offset, int length, int type, int *outPos, int *xpsLen) {
    int i;
    int startCodeIndex = -1;
    
    // 0x00 00 00 01四个字节为StartCode，在两个StartCode之间的内容即为一个完整的NALU。
    // 存储的一般形式为: 00 00 00 01 SPS 00 00 00 01 PPS 00 00 00 01 I帧
    for (i = offset; i < length - 4; i++) {
        if ((0 == data[i]) && (0 == data[i + 1]) && (1 == data[i + 2]) && (type == (0x0F & data[i + 3]))) {
            startCodeIndex = i;
            break;
        }
    }
    
    if (-1 == startCodeIndex) {
        return;
    }
    
    int pos1 = -1;
    for (i = startCodeIndex + 4; i < length - 4; i++) {
        if ((0 == data[i]) && (0 == data[i + 1]) && (1 == data[i + 2])) {
            pos1 = i;
            
            if (data[i - 1] == 0) {
                // 00 00 00 01
                pos1--;
            }
            break;
        }
    }
    
    if (-1 == pos1) {
        return;
    }
    
    *outPos = startCodeIndex + 3;
    *xpsLen = pos1 - startCodeIndex - 3;
    printf("type = %d xpsLen= %d; outPos = %d, pos1 = %d\n", type, *xpsLen, *outPos, pos1);
}

#pragma mark - 解码
- (BOOL)decodeVideoWithData:(unsigned char *)dataRef dataLength:(int)length {
    if (dataRef == nil) {
        return NO;
    }
    self.decodeType = GPUDecoderDecodeTypeH264;
    if (formatDescriptionOut == NULL) {
        [self initDecoderWithData:dataRef length:length];
    }
    /* 确定nDiff值：
     Start Code表现形式：00 00 01 或 00 00 00 01
     Length表现形式：00 00 80 00
     有资料说当一帧图像被编码为多个slice（即需要有多个NALU）时，每个NALU的StartCode为3个字节，否则为4个字节
     */
    int nDiff = 0;
    int nalPackLen = length;
    unsigned char *pTemp = dataRef;
    for (int i = 0; i < length; i++) {
        if (*(pTemp) == 0 && *(pTemp + 1) == 0) {
            if (*(pTemp + 2) == 1) {                                // 00 00 01
                int nalu_type = ((uint8_t)*(pTemp + 3) & 0x1F);
                if (nalu_type == 1 || nalu_type == 5) {
                    nDiff = 3;
                    break;
                }
            } else if (*(pTemp + 2) == 0 && *(pTemp + 3) == 1) {    // 00 00 00 01
                int nalu_type = ((uint8_t)*(pTemp + 4) & 0x1F);
                
                if (nalu_type == 1 || nalu_type == 5) {
                    nDiff = 4;
                    break;
                }
            }
        }
        
        pTemp++;
        nalPackLen--;
    }
    
    if (nDiff == 0) {
        return NO;
    }
    
    int nalu_type = ((uint8_t)*(pTemp + nDiff) & 0x1F);
    
    // 非IDR图像的片、IDR图像的片
    if (nalu_type == 1 || nalu_type == 5) {
        if (nDiff == 3) {
            // 只有2个0 前面补位0
            if (innerLen <= nalPackLen) {
                innerLen = nalPackLen + 1;
                
                // void* realloc(void* ptr, unsigned newsize);
                // realloc是给一个已经分配了地址的指针重新分配空间,参数ptr为原有的空间地址,newsize是重新申请的地址长度
                pInnerData = (unsigned char *)realloc(pInnerData, innerLen);
            }
            
            memcpy(pInnerData + 1, pTemp, nalPackLen);
            pTemp = pInnerData;
            nalPackLen++;
        }
        
        
        CMBlockBufferRef newBBufOut = NULL;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                             pTemp,
                                                             nalPackLen,
                                                             kCFAllocatorNull,
                                                             NULL,
                                                             0,
                                                             nalPackLen,
                                                             0,
                                                             &newBBufOut);
        
        int reomveHeaderSize = nalPackLen - 4;
        const uint8_t sourceBytes[] = { (uint8_t)(reomveHeaderSize >> 24),
            (uint8_t)(reomveHeaderSize >> 16),
            (uint8_t)(reomveHeaderSize >> 8),
            (uint8_t)reomveHeaderSize };
        
        // B.用4字节长度代码（4 byte length code (the length of the NalUnit including the unit code)）替换分隔码（separator code）
        status = CMBlockBufferReplaceDataBytes(sourceBytes, newBBufOut, 0, 4);
        
        // CMSampleBuffer包装了数据采样，就视频而言，CMSampleBuffer可包装压缩视频帧或未压缩视频帧，它组合了如下类型：CMTime（采样的显示时间）、CMVideoFormatDescription（描述了CMSampleBuffer包含的数据）、 CMBlockBuffer（对于压缩视频帧）、CMSampleBuffer（未压缩光栅化图像，可能包含在CVPixelBuffer或 CMBlockBuffer）
        CMSampleBufferRef sbRef = NULL;
        const size_t sampleSizeArray[] = {(size_t)length};
        
        // C. 由CMBlockBuffer创建CMSampleBuffer
        status = CMSampleBufferCreate(kCFAllocatorDefault,
                                      newBBufOut,
                                      true,
                                      NULL,
                                      NULL,
                                      formatDescriptionOut,
                                      1,
                                      0,
                                      NULL,
                                      1,
                                      sampleSizeArray,
                                      &sbRef);
        
        VTDecodeFrameFlags flags = 0;
        VTDecodeInfoFlags flagOut = 0;
        
        // D. 默认的同步解码一个视频帧,解码后的图像会交由didDecompress回调函数，来进一步的处理。
        status = VTDecompressionSessionDecodeFrame(decompressSession,
                                                   sbRef,
                                                   flags,
                                                   &sbRef,
                                                   &flagOut);
        if (status == noErr) {
            // Block until our callback has been called with the last frame
            status = VTDecompressionSessionWaitForAsynchronousFrames(decompressSession);
        }
        
        CFRelease(sbRef);
        sbRef = NULL;
    }
    return YES;
}

- (void)initDecoderWithData:(unsigned char *)dataRef length:(int)length {
    int spsStart = 0;
    int spsLength = 0;
    
    int ppsStart = 0;
    int ppsLength = 0;
    
    read_sps_pps_dataFromData(dataRef, length, GPUDecoder_NAUL_TypeSPS, &spsStart, &spsLength); // 读取sps数据
    read_sps_pps_dataFromData(dataRef, length, GPUDecoder_NAUL_TypePPS, &ppsStart, &ppsLength);// 8代表pps
    
    if (spsLength == 0 || ppsLength == 0) {
        return;
    }
    
    if (_spsRef != NULL) {
        free(_spsRef);
        _spsRef = NULL;
    }
    
    if (_ppsRef != NULL) {
        free(_ppsRef);
        _ppsRef = NULL;
    }
    
    // H.264的SPS和PPS包含了初始化H.264解码器所需要的信息参数，包括编码所用的profile，level，图像的宽和高，deblock滤波器等。
    // 解析过的SPS和PPS
    _spsRef = (unsigned char *)malloc(spsLength);
    memcpy(_spsRef, dataRef + spsStart, spsLength);
    
    _ppsRef = (unsigned char *)malloc(ppsLength);
    memcpy(_ppsRef, dataRef + ppsStart, ppsLength);
    
    const uint8_t* const parameterSetPointers[2] = { _spsRef, _ppsRef };
    const size_t parameterSetSizes[2] = { (size_t)spsLength, (size_t)ppsLength };
    
    // 创建格式描述
    // CMVideoFormatDescriptionCreateFromH264ParameterSets从基础的流数据将SPS和PPS转化为Format Desc
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,
                                                                          &formatDescriptionOut);
    if (status != noErr) {
        return;
    }
    
    VTDecompressionOutputCallbackRecord outPutcallback;
    outPutcallback.decompressionOutputCallback = didDecompress;
    outPutcallback.decompressionOutputRefCon = (__bridge void *)self;
    // destinationImageBufferAttributes
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLESCompatibilityKey,
                                [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey,
                                nil ];
    
    // 1、创建解码会话,初始化VTDecompressionSession，设置解码器的相关信息
    status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                          formatDescriptionOut,
                                          NULL,
                                          (__bridge CFDictionaryRef)attributes,
                                          &outPutcallback,
                                          &decompressSession);
}
- (int)decodeVideoData:(unsigned char *)pData len:(int)len {
    // NAL_UNIT_TYPpe  1:非idr的片;  5 idr
    if (pData == nil) {
        return -1;
    }
    
    self.decodeType = GPUDecoderDecodeTypeH264;
    
//    [self initH264DecoderVideoData:pData len:len];
    
    /* 确定nDiff值：
     Start Code表现形式：00 00 01 或 00 00 00 01
     Length表现形式：00 00 80 00
     有资料说当一帧图像被编码为多个slice（即需要有多个NALU）时，每个NALU的StartCode为3个字节，否则为4个字节
     */
    int nDiff = 0;
    int nalPackLen = len;
    unsigned char *pTemp = pData;
    for (int i = 0; i < len; i++) {
        if (*(pTemp) == 0 && *(pTemp + 1) == 0) {
            if (*(pTemp + 2) == 1) {                                // 00 00 01
                int nalu_type = ((uint8_t)*(pTemp + 3) & 0x1F);
                if (nalu_type == 1 || nalu_type == 5) {
                    nDiff = 3;
                    break;
                }
            } else if (*(pTemp + 2) == 0 && *(pTemp + 3) == 1) {    // 00 00 00 01
                int nalu_type = ((uint8_t)*(pTemp + 4) & 0x1F);
                
                if (nalu_type == 1 || nalu_type == 5) {
                    nDiff = 4;
                    break;
                }
            }
        }
        
        pTemp++;
        nalPackLen--;
    }
    
    if (nDiff == 0) {
        return -1;
    }
    
    int nalu_type = ((uint8_t)*(pTemp + nDiff) & 0x1F);
    
    // 非IDR图像的片、IDR图像的片
    if (nalu_type == 1 || nalu_type == 5) {
        if (nDiff == 3) {
            // 只有2个0 前面补位0
            if (innerLen <= nalPackLen) {
                innerLen = nalPackLen + 1;
                
                // void* realloc(void* ptr, unsigned newsize);
                // realloc是给一个已经分配了地址的指针重新分配空间,参数ptr为原有的空间地址,newsize是重新申请的地址长度
                pInnerData = (unsigned char *)realloc(pInnerData, innerLen);
            }
            
            memcpy(pInnerData + 1, pTemp, nalPackLen);
            pTemp = pInnerData;
            nalPackLen++;
        }
        
        
        CMBlockBufferRef newBBufOut = NULL;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                             pTemp,
                                                             nalPackLen,
                                                             kCFAllocatorNull,
                                                             NULL,
                                                             0,
                                                             nalPackLen,
                                                             0,
                                                             &newBBufOut);
        
        int reomveHeaderSize = nalPackLen - 4;
        const uint8_t sourceBytes[] = { (uint8_t)(reomveHeaderSize >> 24),
            (uint8_t)(reomveHeaderSize >> 16),
            (uint8_t)(reomveHeaderSize >> 8),
            (uint8_t)reomveHeaderSize };
        
        // B.用4字节长度代码（4 byte length code (the length of the NalUnit including the unit code)）替换分隔码（separator code）
        status = CMBlockBufferReplaceDataBytes(sourceBytes, newBBufOut, 0, 4);
        
        // CMSampleBuffer包装了数据采样，就视频而言，CMSampleBuffer可包装压缩视频帧或未压缩视频帧，它组合了如下类型：CMTime（采样的显示时间）、CMVideoFormatDescription（描述了CMSampleBuffer包含的数据）、 CMBlockBuffer（对于压缩视频帧）、CMSampleBuffer（未压缩光栅化图像，可能包含在CVPixelBuffer或 CMBlockBuffer）
        CMSampleBufferRef sbRef = NULL;
        const size_t sampleSizeArray[] = {(size_t)len};
        
        // C. 由CMBlockBuffer创建CMSampleBuffer
        status = CMSampleBufferCreate(kCFAllocatorDefault,
                                      newBBufOut,
                                      true,
                                      NULL,
                                      NULL,
                                      formatDescriptionOut,
                                      1,
                                      0,
                                      NULL,
                                      1,
                                      sampleSizeArray,
                                      &sbRef);
        
        VTDecodeFrameFlags flags = 0;
        VTDecodeInfoFlags flagOut = 0;
        
        // D. 默认的同步解码一个视频帧,解码后的图像会交由didDecompress回调函数，来进一步的处理。
        status = VTDecompressionSessionDecodeFrame(decompressSession,
                                                   sbRef,
                                                   flags,
                                                   &sbRef,
                                                   &flagOut);
        if (status == noErr) {
            // Block until our callback has been called with the last frame
            status = VTDecompressionSessionWaitForAsynchronousFrames(decompressSession);
        }
        
        CFRelease(sbRef);
        sbRef = NULL;
    }
    
    return 0;
}

#pragma mark - 销毁解码器
- (void)destroy {
    if (_spsRef != NULL) {
        free(_spsRef);
        _spsRef = NULL;
    }
    if (_ppsRef != NULL) {
        free(_ppsRef);
        _ppsRef = NULL;
    }
    if (decompressSession) {
        VTDecompressionSessionInvalidate(decompressSession);
        CFRelease(decompressSession);
        decompressSession = NULL;
    }
    if (formatDescriptionOut) {
        CFRelease(formatDescriptionOut);
        formatDescriptionOut = NULL;
    }
    if (pInnerData != NULL) {
        free(pInnerData);
        pInnerData = NULL;
    }
    innerLen = 0;
}
//- (void)closeDecoder {
//    NSLog(@"closeDecoder %@", self);
//
//    if (_spsRef != NULL) {
//        free(_spsRef);
//        _spsRef = NULL;
//    }
//
//    if (_ppsRef != NULL) {
//        free(_ppsRef);
//        _ppsRef = NULL;
//    }
//
//    if (decompressSession) {
//        // 释放解码会话
//        VTDecompressionSessionInvalidate(decompressSession);
//        CFRelease(decompressSession);
//        decompressSession = NULL;
//    }
//
//    if (formatDescriptionOut) {
//        CFRelease(formatDescriptionOut);
//        formatDescriptionOut = NULL;
//    }
//
//    if (pInnerData != NULL) {
//        free(pInnerData);
//        pInnerData = NULL;
//    }
//
//    innerLen = 0;
//}


@end
