//
//  RTSPStreamReader.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "RTSPStreamReader.h"
#import "GPUDecoder.h"
#include <set>
#include <string.h>
#include <vector>
#include <pthread.h>
#import "CarEyeAudioDecoder.h"
#import "KxMovieDecoder.h"
struct FrameInfo {
    FrameInfo() : pBuf(NULL), frameLen(0), type(0), timeStamp(0), width(0), height(0){}
    
    unsigned char *pBuf;
    int frameLen;
    int type;
    CGFloat timeStamp;
    int width;
    int height;
};

class com {
public:
    bool operator ()(FrameInfo *lhs, FrameInfo *rhs) const {
        if (lhs == NULL || rhs == NULL) {
            return true;
        }
        
        return lhs->timeStamp < rhs->timeStamp;
    }
};

std::multiset<FrameInfo *, com> recordVideoFrameSet;
std::multiset<FrameInfo *, com> recordAudioFrameSet;

int isKeyFrame = 0; // 是否到了I帧
int *stopRecord = (int *)malloc(sizeof(int));// 停止录像


#pragma mark ====================== lib callback  ===================


@interface RTSPStreamReader()<GPUDecoderDelegate>
@property (nonatomic, readwrite) BOOL running;
@property (nonatomic, strong) NSThread *videoThread;
@property (nonatomic, strong) NSThread *audioThread;

- (void)pushFrame:(char *)pBuf frameInfo:(CarEye_RtspFrameInfo *)info type:(int)type;
@end
@implementation RTSPStreamReader
{
    // RTSP拉流句柄
    CarEye_RTSP_Handle rtspHandle;
    
    // 互斥锁
    pthread_mutex_t mutexVideoFrame;
    pthread_mutex_t mutexAudioFrame;
    pthread_mutex_t mutexChan;
    pthread_mutex_t mutexRecordFrame;
    
    void *_videoDecHandle;  // 视频解码句柄
    CarEyeAudioHandle *_audioDecHandle;  // 音频解码句柄
    
    CarEye_MediaInfo *_mediaInfo;   // 媒体信息
    
    std::multiset<FrameInfo *, com> videoFrameSet;
    std::multiset<FrameInfo *, com> audioFrameSet;
    
    CGFloat lastFrameTimeStamp;
    NSTimeInterval beforeDecoderTimeStamp;
    NSTimeInterval afterDecoderTimeStamp;
    
//    CGFloat _lastVideoFramePosition;
    
    // 视频硬解码器
    GPUDecoder *_decoder;
}
//+ (void)startUp {
//    DecodeRegiestAll();
//}

/*
 * Comments: 回调方法，在接收到媒体数据或者网络事件变更时会触发该回调
 * Param channedlId: 打开的对应通道号
 * Param userPtr: 用户传入的数据
 * Param frameType: 媒体帧类型
 * Param pBuf: 可能为错误信息也可能是媒体裸流数据，根据frameType而定
 * Param frameInfo: 媒体信息
 * @Return int
 */

int revRTSPStreamCallback( int channelId, void *userPtr, CarEye_FrameFlag frameType, char *pBuf, CarEye_RtspFrameInfo* frameInfo) {
    if (userPtr == NULL) {
        return 0;
    }
    
    if (pBuf == NULL) {
        return 0;
    }
    
    RTSPStreamReader *reader = (__bridge RTSPStreamReader *)userPtr;
    if (frameType == CAREYE_INFO_FLAG) {
        CarEye_MediaInfo mediaInfo = *((CarEye_MediaInfo *)pBuf);
//        NSLog(@"RTSP DESCRIBE Get Media Info: type:%u fps:%u codecType:%u channel:%u sampleRate:%u \n",
//              mediaInfo.ty,
//              mediaInfo.fps,
//              mediaInfo.codec,
//              mediaInfo.channels,
//              mediaInfo.bits_per_sample);
        if (mediaInfo.u32AudioChannel <= 0 || mediaInfo.u32AudioChannel > 2) {
                 mediaInfo.u32AudioChannel = 1;
        }
        [reader recvAudioInfo:&mediaInfo];
    }else if (frameType == CAREYE_AFRAME_FLAG) { // 音频帧
        [reader pushFrame:pBuf frameInfo:frameInfo type:frameType];
    }else if (frameType == CAREYE_VFRAME_FLAG) { // 视频帧
        if (frameInfo->type == VIDEO_FRAME_I) {
            
        }
        if (frameInfo->codec == CAREYE_VCODE_H264) {
            [reader pushFrame:pBuf frameInfo:frameInfo type:frameType];
        }
    }
    
   /*
    if (frameInfo != NULL) {
        if (frameType == CAREYE_AFRAME_FLAG) {// EASY_SDK_AUDIO_FRAME_FLAG音频帧标志
            [reader pushFrame:pBuf frameInfo:frameInfo type:frameType];
        } else if (frameType == CAREYE_VFRAME_FLAG &&
                   frameInfo->codec == CAREYE_VCODE_H264) { // H264视频编码
            [reader pushFrame:pBuf frameInfo:frameInfo type:frameType];
        }
    } else {
        if (frameType == CAREYE_INFO_FLAG) {// CAREYE_INFO_FLAG媒体信息
            CarEye_RtspFrameInfo mediaInfo = *((CarEye_RtspFrameInfo *)pBuf);
            NSLog(@"RTSP DESCRIBE Get Media Info: type:%u fps:%u codecType:%u channel:%u sampleRate:%u \n",
                  mediaInfo.type,
                  mediaInfo.fps,
                  mediaInfo.codec,
                  mediaInfo.channels,
                  mediaInfo.bits_per_sample);
            [reader recvAudioInfo:&mediaInfo];
        }
    }
    */
    return 0;
}
#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        // 动态方式是采用pthread_mutex_init()函数来初始化互斥锁
        pthread_mutex_init(&mutexVideoFrame, 0);
        pthread_mutex_init(&mutexAudioFrame, 0);
        pthread_mutex_init(&mutexChan, 0);
        pthread_mutex_init(&mutexRecordFrame, 0);
        
        _videoDecHandle = NULL;
        _audioDecHandle = NULL;
        
        // 初始化硬解码器
        //        _decoder = [[HWVideoDecoder alloc] initWithDelegate:self];
        _decoder = [[GPUDecoder alloc] init];
        _decoder.delegate = self;
        self.enableAudio = YES;

    }
    return self;
}
//- (id)initWithUrl:(NSString *)url {
//    if (self = [super init]) {
//    }
//    
//    return self;
//}

#pragma mark - public method

- (void)startWithURL:(NSString *)url {
    self.url = url;

    
//    _lastVideoFramePosition = 0;
    _running = YES;
    
    self.videoThread = [[NSThread alloc] initWithTarget:self selector:@selector(runloopForVideo) object:nil];
    [self.videoThread start];
    
    self.audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(runloopForAudio) object:nil];
    [self.audioThread start];
}

- (void)stop {
    if (!_running) {
        return;
    }
    
    if (rtspHandle != NULL) {
        CarEye_RtspEventRegister(rtspHandle, NULL);
        CarEye_RtspStop(rtspHandle);// 关闭网络流
    }

    _running = false;
    [self.videoThread cancel];
    [self.audioThread cancel];
}

#pragma mark - 子线程方法

- (void) initRtspHandle {
    // ------------ 加锁mutexChan ------------
    pthread_mutex_lock(&mutexChan);
    if (rtspHandle == NULL) {
        int ret = CarEye_RtspCreate(&rtspHandle); // 创建句柄
        
        if (ret != 0) {
            NSLog(@"EasyRTSP_Init err %d", ret);
        } else {
            /* 注册句柄对应的回调函数 */
            CarEye_RtspEventRegister(rtspHandle, revRTSPStreamCallback);
            
            /*
             * Comments: 打开网络流开始拉取RTSP数据
             * Param handle: RTSP客户端句柄
             * Param channelId: 用户指定为的通道号，回调函数的channelId形参即为该通道号
             * Param url: 拉取网络流的URL地址
             * Param connType: 连接类型，RTP数据是基于TCP或者UDP
             * Param mediaType: CarEye_FrameFlag 获取的媒体类型，这里设置为视频和音频
             * Param userName: RTSP链接的用户名，无->NULL
             * Param password: RTSP链接的密码，无->NULL
             * Param userPtr: 用户传入的自定义数据，回调函数的userPts即为该数据，这里传入当前处理类RTSPStreamReader
             * Param reCount: 失败自动重连次数，1000表示失败后一直自动重连
             * Param outRtpPacket: 为0回调函数输出完整的帧数据，为1回到输出RTP包数据
             * Param heartbeatType: 心跳类型 0x00:不发送心跳 0x01:OPTIONS心跳 0x02:GET_PARAMETER心跳
             * Param verbosity: 日志打印级别，0表示不输出
             * @Return void
             */
            
            ret = CarEye_RtspStart(rtspHandle,
                                      1,
                                      (char *)[self.url UTF8String],
                                      CAREYE_ON_TCP,
                                      CarEye_FrameFlag(CAREYE_VFRAME_FLAG | CAREYE_AFRAME_FLAG),
                                      NULL,
                                      NULL,
                                      (__bridge void *)self,
                                      1000, // 自动重连
                                      0,
                                      0x01,// 发送心跳包
                                      3);       // 日志打印输出等级，0表示不输出
            NSLog(@"打开拉流结果 ret = %d", ret);
        }
    }
    pthread_mutex_unlock(&mutexChan);
    // ------------ 解锁mutexChan ------------
}

// 视频处理
- (void)runloopForVideo {
    
    while (_running) {
        [self initRtspHandle];
        
        // ------------ 加锁mutexFrame ------------
        pthread_mutex_lock(&mutexVideoFrame);
        
        int count = (int) videoFrameSet.size();
        if (count == 0) {
            pthread_mutex_unlock(&mutexVideoFrame);
            usleep(5 * 1000);
            continue;
        }
        
        FrameInfo *frame = *(videoFrameSet.begin());
        videoFrameSet.erase(videoFrameSet.begin());// erase()函数的功能是用来删除容器中的元素
        
        beforeDecoderTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        
        pthread_mutex_unlock(&mutexVideoFrame);
        // ------------ 解锁mutexFrame ------------
        
//        if (self.useHWDecoder) {
//            [_decoder decodeVideoData:frame->pBuf len:frame->frameLen];
        [_decoder decodeVideoWithData:frame->pBuf dataLength:frame->frameLen];
//        } else {
//            [self decodeVideoFrame:frame];
//        }
        
        delete []frame->pBuf;
        
        // 帧里面有个timestamp 是当前帧的时间戳， 先获取下系统时间A，然后解码播放，解码后获取系统时间B， B-A就是本次的耗时。sleep的时长就是 当期帧的timestamp  减去 上一个视频帧的timestamp 再减去 这次的耗时
        afterDecoderTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        if (lastFrameTimeStamp != 0) {
            float t = frame->timeStamp - lastFrameTimeStamp - (afterDecoderTimeStamp - beforeDecoderTimeStamp);
            usleep(t);
            
            //            NSLog(@" --->> %f :  %f, %f ", t, frame->timeStamp - lastFrameTimeStamp, afterDecoderTimeStamp - beforeDecoderTimeStamp);
        }
        
        lastFrameTimeStamp = frame->timeStamp;
        
        delete frame;
    }
    
    [self removeVideoFrameSet];
    
    if (_videoDecHandle != NULL) {
//        DecodeClose(_videoDecHandle);
//        _videoDecHandle = NULL;
    }
        [_decoder destroy];
}
- (void)removeVideoFrameSet {
    // ------------------ frameSet ------------------
    pthread_mutex_lock(&mutexVideoFrame);
    
    std::set<FrameInfo *>::iterator videoItem = videoFrameSet.begin();
    while (videoItem != videoFrameSet.end()) {
        FrameInfo *frameInfo = *videoItem;
        delete []frameInfo->pBuf;
        delete frameInfo;
        
        videoItem++;   // 很关键, 主动前移指针
    }
    videoFrameSet.clear();
    
    pthread_mutex_unlock(&mutexVideoFrame);
}

#pragma mark - 视频处理
/* 软解码 暂时不用
- (void)decodeVideoFrame:(FrameInfo *)video {
    if (_videoDecHandle == NULL) {
        DEC_CREATE_PARAM param;
        param.nMaxImgWidth = video->width;
        param.nMaxImgHeight = video->height;
        param.coderID = CODER_H264;
        param.method = IDM_SW;
        _videoDecHandle = DecodeCreate(&param);
    }

    DEC_DECODE_PARAM param;
    param.pStream = video->pBuf;
    param.nLen = video->frameLen;
    param.need_sps_head = false;

    DVDVideoPicture picture;
    memset(&picture, 0, sizeof(picture));
    picture.iDisplayWidth = video->width;
    picture.iDisplayHeight = video->height;
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    int nRet = DecodeVideo(_videoDecHandle, &param, &picture);
    NSTimeInterval decodeInterval = [NSDate timeIntervalSinceReferenceDate] - now;
    if (nRet) {
        @autoreleasepool {
            KxVideoFrameRGB *frame = [[KxVideoFrameRGB alloc] init];
            frame.width = param.nOutWidth;
            frame.height = param.nOutHeight;
            frame.linesize = param.nOutWidth * 3;
            frame.hasAlpha = NO;
            frame.rgb = [NSData dataWithBytes:param.pImgRGB length:param.nLineSize * param.nOutHeight];
            frame.position = video->timeStamp;
            
            if (_lastVideoFramePosition == 0) {
                _lastVideoFramePosition = video->timeStamp;
            }
            
            CGFloat duration = video->timeStamp - _lastVideoFramePosition - decodeInterval;
            if (duration >= 1.0 || duration <= -1.0) {
                duration = 0.02;
            }
            
            frame.duration = duration;
            _lastVideoFramePosition = video->timeStamp;
            
            afterDecoderTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
            if (self.frameOutputBlock) {
                self.frameOutputBlock(frame);
            }
        }
    }
}
*/
#pragma mark - 音频处理
- (void)setMediaInfo:(CarEye_MediaInfo *)mediaInfo {
    _mediaInfo = mediaInfo;
}
- (void)runloopForAudio {
    
    while (_running) {
        if (rtspHandle == NULL) {
            continue;
        }
        
        // ------------ 加锁mutexFrame ------------
        pthread_mutex_lock(&mutexAudioFrame);
        
        int count = (int) audioFrameSet.size();
        if (count == 0) {
            pthread_mutex_unlock(&mutexAudioFrame);
            usleep(5 * 1000);
            continue;
        }
        
        FrameInfo *frame = *(audioFrameSet.begin());
        audioFrameSet.erase(audioFrameSet.begin());// erase()函数的功能是用来删除容器中的元素
        
        pthread_mutex_unlock(&mutexAudioFrame);
        // ------------ 解锁mutexFrame ------------
        
        if (self.enableAudio) {
            [self decodeAudioFrame:frame];
        }
        
        delete []frame->pBuf;
        delete frame;
    }
    
    [self removeAudioFrameSet];
//    pthread_mutex_lock(<#pthread_mutex_t * _Nonnull#>)
    if (_audioDecHandle != NULL) {
        CarEyeAudioDecodeClose(_audioDecHandle);
        _audioDecHandle = NULL;
    }
    
}


- (void)decodeAudioFrame:(FrameInfo *)audioInfo {
    if (_audioDecHandle == NULL) {
        _audioDecHandle = CarEyeAudioDecoderCreate(*(_mediaInfo));
//        _audioDecHandle = CarEyeAudioDecoder(self.mediaInfo->u32AudioCodec, self.mediaInfo->u32AudioSamplerate, self.mediaInfo->u32AudioChannel, 16);
    }
    if (_audioDecHandle == NULL) {
        return;
    }
    unsigned char pcmBuf[10 * 1024] = { 0 };
    int pcmLen = 0;
    int ret = CarEyeAudioDecode((CarEyeAudioHandle *)_audioDecHandle, audioInfo->pBuf, 0, audioInfo->frameLen, pcmBuf, &pcmLen);
    
    if (ret == 0) {
        @autoreleasepool {
            KxAudioFrame *frame = [[KxAudioFrame alloc] init];
            frame.samples = [NSData dataWithBytes:pcmBuf length:pcmLen];
            frame.position = audioInfo->timeStamp;
            if (self.getAVFrameSuccCall) {
                self.getAVFrameSuccCall(frame);
            }
        }
    }
}


- (void)removeAudioFrameSet {
    pthread_mutex_lock(&mutexAudioFrame);
    
    std::set<FrameInfo *>::iterator it = audioFrameSet.begin();
    while (it != audioFrameSet.end()) {
        FrameInfo *frameInfo = *it;
        delete []frameInfo->pBuf;
        delete frameInfo;
        
        it++;   // 很关键, 主动前移指针
    }
    audioFrameSet.clear();
    
    pthread_mutex_unlock(&mutexAudioFrame);
}

- (void) removeRecordFrameSet {
    // ------------------ recordVideoFrameSet ------------------
    pthread_mutex_lock(&mutexRecordFrame);
    std::set<FrameInfo *>::iterator videoItem = recordVideoFrameSet.begin();
    while (videoItem != recordVideoFrameSet.end()) {
        FrameInfo *frameInfo = *videoItem;
        delete []frameInfo->pBuf;
        delete frameInfo;
        videoItem++;
    }
    recordVideoFrameSet.clear();
    pthread_mutex_unlock(&mutexRecordFrame);
    
    // ------------------ recordAudioFrameSet ------------------
    pthread_mutex_lock(&mutexRecordFrame);
    std::set<FrameInfo *>::iterator audioItem = recordAudioFrameSet.begin();
    while (audioItem != recordAudioFrameSet.end()) {
        FrameInfo *frameInfo = *audioItem;
        delete []frameInfo->pBuf;
        delete frameInfo;
        audioItem++;
    }
    recordAudioFrameSet.clear();
    pthread_mutex_unlock(&mutexRecordFrame);
}

#pragma mark - 录像

/**
 注册av_read_frame的回调函数
 
 @param opaque URLContext结构体
 @param buf buf
 @param buf_size buf_size
 @return 0
 */
int read_video_packet(void *opaque, uint8_t *buf, int buf_size) {
    int count = (int) recordVideoFrameSet.size();
    if (count == 0) {
        return 0;
    }
    
    FrameInfo *frame = *(recordVideoFrameSet.begin());
    recordVideoFrameSet.erase(recordVideoFrameSet.begin());
    
    if (frame == NULL || frame->pBuf == NULL) {
        return 0;
    }
    
    int frameLen = frame->frameLen;
    memcpy(buf, frame->pBuf, frameLen);
    
    delete []frame->pBuf;
    delete frame;
    
    return frameLen;
}

/**
 注册av_read_frame的回调函数
 
 @param opaque URLContext结构体
 @param buf buf
 @param buf_size buf_size
 @return 0
 */
int read_audio_packet(void *opaque, uint8_t *buf, int buf_size) {
    int count = (int) recordAudioFrameSet.size();
    if (count == 0) {
        return 0;
    }
    
    FrameInfo *frame = *(recordAudioFrameSet.begin());
    recordAudioFrameSet.erase(recordAudioFrameSet.begin());
    
    if (frame == NULL || frame->pBuf == NULL) {
        return 0;
    }
    
    int frameLen = frame->frameLen;
    memcpy(buf, frame->pBuf, frameLen);
    
    delete []frame->pBuf;
    delete frame;
    
    return frameLen;
}

#pragma mark - private method

- (void)readMediaFrameInfo:(CarEye_MediaInfo *)info {
    self.mediaInfo = info;
}
// 获得媒体类型
- (void)recvAudioInfo:(CarEye_MediaInfo *)info {
    self.mediaInfo = info;
    if (_audioDecHandle == NULL) {
                _audioDecHandle = CarEyeAudioDecoderCreate(*(_mediaInfo));
//        _audioDecHandle = CarEyeAudioDecoder(self.mediaInfo->u32AudioCodec, self.mediaInfo->u32AudioSamplerate, self.mediaInfo->u32AudioChannel, 16);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.succCall) {
            self.succCall();
        }
    });
}

- (void)pushFrame:(char *)pBuf frameInfo:(CarEye_RtspFrameInfo *)info type:(int)type {
    if (!_running || pBuf == NULL) {
        return;
    }
    
    FrameInfo *frameInfo = (FrameInfo *)malloc(sizeof(FrameInfo));
    frameInfo->type = type;
    frameInfo->frameLen = info->length;
    frameInfo->pBuf = new unsigned char[info->length];
    frameInfo->width = info->width;
    frameInfo->height = info->height;
    // 毫秒为单位(1秒=1000毫秒 1秒=1000000微秒)
    //    frame->timeStamp = info->timestamp_sec + (float)(info->timestamp_usec / 1000.0) / 1000.0;
    frameInfo->timeStamp = info->timestamp_sec * 1000 + info->timestamp_usec / 1000.0;
    
    memcpy(frameInfo->pBuf, pBuf, info->length);
    
    // 根据时间戳排序
    if (type == CAREYE_AFRAME_FLAG) {
        pthread_mutex_lock(&mutexAudioFrame);    // 加锁
        audioFrameSet.insert(frameInfo);
        pthread_mutex_unlock(&mutexAudioFrame);  // 解锁
    } else {
        pthread_mutex_lock(&mutexVideoFrame);    // 加锁
        videoFrameSet.insert(frameInfo);
        pthread_mutex_unlock(&mutexVideoFrame);  // 解锁
    }
   /*
    // 录像：保存视频的内容
    if (_recordFilePath) {
        
        if (isKeyFrame == 0) {
            if (info->type == EASY_SDK_VIDEO_FRAME_I) {// 视频帧类型
                isKeyFrame = 1;
                
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, NULL);
                dispatch_after(time, queue, ^{
                    // 开始录像
                    *stopRecord = 0;
                    muxer([_recordFilePath UTF8String], stopRecord, read_video_packet, read_audio_packet);
                });
            }
        }
        
        if (isKeyFrame == 1) {
            FrameInfo *frame = (FrameInfo *)malloc(sizeof(FrameInfo));
            frame->type = type;
            frame->frameLen = info->length;
            frame->pBuf = new unsigned char[info->length];
            frame->width = info->width;
            frame->height = info->height;
            // 毫秒为单位(1秒=1000毫秒 1秒=1000000微秒)
            //            frame->timeStamp = info->timestamp_sec + (float)(info->timestamp_usec / 1000.0) / 1000.0;
            frameInfo->timeStamp = info->timestamp_sec * 1000 + info->timestamp_usec / 1000.0;
            
            memcpy(frame->pBuf, pBuf, info->length);
            
            if (type == EASY_SDK_AUDIO_FRAME_FLAG) {
                //                pthread_mutex_lock(&mutexRecordFrame);    // 加锁
                //                recordAudioFrameSet.insert(frame);// 根据时间戳排序
                //                pthread_mutex_unlock(&mutexRecordFrame);  // 解锁
                
                // 暂时不录制音频
                delete []frame->pBuf;
                delete frame;
            }
            
            if (type == CAREYE_VFRAME_FLAG &&    // EASY_SDK_VIDEO_FRAME_FLAG视频帧标志
                info->codec == CAREYE_VCODE_H264) { // H264视频编码
                pthread_mutex_lock(&mutexRecordFrame);    // 加锁
                recordVideoFrameSet.insert(frame);// 根据时间戳排序
                pthread_mutex_unlock(&mutexRecordFrame);  // 解锁
            }
        }
    }
    */
}

#pragma mark ====================== GPUDecoderDelegate  ===================
// 解码后回调
- (void)receivePictureFrame:(KxMovieFrame *)frame {
    afterDecoderTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    if(self.getAVFrameSuccCall) {
        self.getAVFrameSuccCall(frame);
    }
}


/*
#pragma mark - HWVideoDecoderDelegate

-(void) getDecodePictureData:(KxVideoFrame *)frame {
    afterDecoderTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    if (self.getAVFrameSuccCall) {
        self.getAVFrameSuccCall(frame);
    }
}

-(void) getDecodePixelData:(CVImageBufferRef)frame {
    NSLog(@"--> %@", frame);
}
*/
#pragma mark - dealloc

- (void)dealloc {
    [self removeVideoFrameSet];
    [self removeAudioFrameSet];
    [self removeRecordFrameSet];
    
    // 注销互斥锁
    pthread_mutex_destroy(&mutexVideoFrame);
    pthread_mutex_destroy(&mutexAudioFrame);
    pthread_mutex_destroy(&mutexChan);
    pthread_mutex_destroy(&mutexRecordFrame);
    
    if (rtspHandle != NULL) {
        /* 释放RTSPClient 参数为RTSPClient句柄 */
        CarEye_RtspRelease(&rtspHandle);
        rtspHandle = NULL;
    }
}

#pragma mark - getter/setter

- (CarEye_MediaInfo *)mediaInfo {
    return _mediaInfo;
}
/*
// 设置录像的路径
- (void) setRecordFilePath:(NSString *)recordFilePath {
    if ((_recordFilePath) && (!recordFilePath)) {
        _recordFilePath = recordFilePath;
        
        *stopRecord = 1;
        muxer(NULL, stopRecord, read_video_packet, read_audio_packet);
        isKeyFrame = 0;
    }
    
    _recordFilePath = recordFilePath;
}
*/
@end
