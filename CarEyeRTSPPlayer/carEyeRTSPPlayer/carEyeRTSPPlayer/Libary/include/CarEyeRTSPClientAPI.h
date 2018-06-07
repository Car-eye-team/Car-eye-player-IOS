/*
 * Car eye 车辆管理平台: www.car-eye.cn
 * Car eye 开源网址: https://github.com/Car-eye-team
 * CarEyeRTSPClientAPI.h
 *
 * Author: Wgj
 * Date: 2018-04-03 21:30
 * Copyright 2018
 *
 * CarEye RTSP客户端接口声明
 */
 
#ifndef __CAREYE_RTSP_CLIENT_H__
#define __CAREYE_RTSP_CLIENT_H__

#ifdef _WIN32
#define CE_API  __declspec(dllexport)
#define CE_APICALL  __stdcall
#else
#define CE_API
#define CE_APICALL 
#endif

// RTSP客户端对象句柄定义
#define CarEye_RTSP_Handle void*

// 视频编码类型定义
typedef enum __VIDEO_CODE_TYPE__
{
	// H264编码
	CAREYE_VCODE_H264 = 0x1C,
	// H265编码
	CAREYE_VCODE_H265 = 0x48323635,
	// MJPEG编码
	CAREYE_VCODE_MJPEG = 0x08,
	// MPEG4编码
	CAREYE_VCODE_MPEG4 = 0x0D,
}CarEye_VCodeType;

// 音频编码类型定义
typedef enum __AUDIO_CODE_TYPE__
{
	// AAC编码
	CAREYE_ACODE_AAC = 0x15002,
	// G711 Ulaw编码
	CAREYE_ACODE_G711U = 0x10006,
	// G711 Alaw编码
	CAREYE_ACODE_G711A = 0x10007,
	// G726编码
	CAREYE_ACODE_G726 = 0x1100B,
}CarEye_ACodeType;

// 视频帧类型定义
typedef enum __VIDEO_FRAME_TYPE__
{
	// I帧
	VIDEO_FRAME_I = 0x01,
	// P帧
	VIDEO_FRAME_P = 0x02,
	// B帧
	VIDEO_FRAME_B = 0x03,
	// JPEG
	VIDEO_FRAME_J = 0x04,
}CarEyeVideoFrameType;

// 媒体帧类型标志定义
typedef enum __FRAME_FLAG_TYPE__
{
	// 视频帧标识
	CAREYE_VFRAME_FLAG = 0x00000001,
	// 音频帧标识
	CAREYE_AFRAME_FLAG = 0x00000002,
	// 事件帧标识
	CAREYE_EFRAME_FLAG = 0x00000004,
	// RTP帧标识
	CAREYE_RFRAME_FLAG = 0x00000008,
	// SDP帧标识
	CAREYE_SFRAME_FLAG = 0x00000010,
	// 媒体类型标识
	CAREYE_INFO_FLAG = 0x00000020,
}CarEye_FrameFlag;

// 帧信息定义
typedef struct __RTSP_FRAME_INFO_T
{
	// 音视频编码格式 参考CarEye_VCodeType与CarEye_ACodeType定义
	unsigned int	codec;
	
	// 视频帧类型，参考CarEyeVideoFrameType定义
	unsigned int	type;
	// 视频帧率
	unsigned char	fps;
	// 视频宽度像素
	unsigned short	width;
	// 视频的高度像素
	unsigned short  height;

	// 如果为关键帧则该字段为spslen + 4
	unsigned int	reserved1;
	// 如果为关键帧则该字段为spslen+4+ppslen+4
	unsigned int	reserved2;

	// 音频采样率
	unsigned int	sample_rate;
	// 音频声道数
	unsigned int	channels;
	// 音频采样精度
	unsigned int	bits_per_sample;

	// 音视频帧大小
	unsigned int	length;
	// 时间戳,微妙数
	unsigned int    timestamp_usec;
	// 时间戳 秒数
	unsigned int	timestamp_sec;

	// 比特率
	float			bitrate;
	// 丢包率
	float			losspacket;
}CarEye_RtspFrameInfo;
/* 媒体信息 */
typedef struct
{
    unsigned int u32VideoCodec;    /* 视频编码类型 */
    unsigned int u32VideoFps;    /* 视频帧率 */
    
    unsigned int u32AudioCodec;    /* 音频编码类型 */
    unsigned int u32AudioSamplerate;  /* 音频采样率 */
    unsigned int u32AudioChannel;   /* 音频通道数 */
    unsigned int u32AudioBitsPerSample;  /* 音频采样精度 */
    
    unsigned int u32VpsLength;   /* VPS 帧长度*/
    unsigned int u32SpsLength;   /* SPS 帧长度 */
    unsigned int u32PpsLength;   /* PPS 帧长度 */
    unsigned int u32SeiLength;   /* SEI 帧长度 */
    unsigned char  u8Vps[255];   /* VPS 帧内容 */
    unsigned char  u8Sps[255];   /* SPS 帧内容 */
    unsigned char  u8Pps[128];   /* PPS 帧内容 */
    unsigned char  u8Sei[128];   /* SEI 帧内容 */
}CarEye_MediaInfo;

// 连接类型定义
typedef enum __RTP_CONNECT_TYPE__
{
	// RTP基于TCP连接
	CAREYE_ON_TCP = 0x01,
	// RTP基于UDP连接
	CAREYE_ON_UDP = 0x02,
}CarEyeRtpConnectType;


/*
* Comments: 回调方法，在接收到媒体数据或者网络事件变更时会触发该回调
* Param channedlId: 打开的对应通道号
* Param userPtr: 用户传入的数据
* Param frameType: 媒体帧类型
* Param pBuf: 可能为错误信息也可能是媒体裸流数据，根据frameType而定
* Param frameInfo: 媒体信息
* @Return int
*/
typedef int (CE_APICALL *RTSPSourceCallBack)( int channelId, void *userPtr, CarEye_FrameFlag frameType, char *pBuf, CarEye_RtspFrameInfo* frameInfo);

#ifdef __cplusplus
extern "C"
{
#endif
	/*
	* Comments: 获取最后一次错误的错误码
	* Param handle: RTSP客户端句柄
	* @Return int 错误码
	*/
	CE_API int CE_APICALL CarEye_GetRtspErrCode(CarEye_RTSP_Handle handle);

	/*
	* Comments: 使用有效的Key进行CarEye RTSP客户端的注册以便使用, 使用本系统前必须进行注册才能正常使用
	* Param key: 有效的密钥
	* Param packName: 针对Android系统的应用程序包名
	* @Return int CAREYE_NOERROR: 成功, 返回结果参考CarEyeError
	*/
#ifdef ANDROID
	CE_API int CE_APICALL CarEye_RtspActivate(char *key, char* packName);
#else
	CE_API int CE_APICALL CarEye_RtspActivate(char *key);
#endif

	/*
	* Comments: 创建RTSP客户端句柄  
	* Param handle: [输出] 成功返回有效句柄
	* @Return 返回0表示成功，返回非0表示失败
	*/
	CE_API int CE_APICALL CarEye_RtspCreate(CarEye_RTSP_Handle *handle);

	/*
	* Comments: 释放RTSP客户端
	* Param handle: 要释放的RTSP客户端句柄
	* @Return void
	*/
	CE_API int CE_APICALL CarEye_RtspRelease(CarEye_RTSP_Handle *handle);

	/*
	* Comments: 注册RTSP事件回调
	* Param handle: RTSP客户端句柄
	* Param callback: 回调方法
	* @Return void
	*/
	CE_API int CE_APICALL CarEye_RtspEventRegister(CarEye_RTSP_Handle handle, RTSPSourceCallBack callback);

	/*
	* Comments: 打开网络流开始拉取RTSP数据
	* Param handle: RTSP客户端句柄
	* Param channelId: 用户指定为的通道号，回调函数的channelId形参即为该通道号
	* Param url: 拉取网络流的URL地址
	* Param connType: 连接类型，RTP数据是基于TCP或者UDP
	* Param mediaType: 获取的媒体类型
	* Param userName: RTSP链接的用户名，无->NULL
	* Param password: RTSP链接的密码，无->NULL
	* Param userPtr: 用户传入的自定义数据，回调函数的userPts即为该数据
	* Param reCount: 失败自动重连次数，1000表示失败后一直自动重连
	* Param outRtpPacket: 为0回调函数输出完整的帧数据，为1回到输出RTP包数据
	* Param heartbeatType: 心跳类型 0x00:不发送心跳 0x01:OPTIONS心跳 0x02:GET_PARAMETER心跳
	* Param verbosity: 日志打印级别，0表示不输出
	* @Return void
	*/
	CE_API int CE_APICALL CarEye_RtspStart(CarEye_RTSP_Handle handle, int channelId, char *url, 
										CarEyeRtpConnectType connType, CarEye_FrameFlag mediaType, 
										char *userName, char *password, void *userPtr, 
										int reCount, int outRtpPacket, int heartbeatType, int verbosity);
		
	/*
	* Comments: 停止关闭网络流的拉取
	* Param handle: RTSP客户端句柄
	* @Return void
	*/
	CE_API int CE_APICALL CarEye_RtspStop(CarEye_RTSP_Handle handle);

#ifdef __cplusplus
}
#endif

#endif
