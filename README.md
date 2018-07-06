# Car-Eye 开源平台 iOS播放客户端

目前支持：
* 音视频播放

* 断开重连

  ## 一、RTSP 视频流播放

  #### • car-eye RTSP 播放器目前支持H.264**，**H.265**，**MPEG4**，**MJPEG 视频软硬解码，音频方面支持AAC、G711A,G711U,G726等。

  #### • 运行说明：

  下载demo，运行 双击CarEyePlayer.xcworkspace 文件，内含carEyeRTSPPlayer.xcodeproj 工程文件，之后将会支持 RTMP 视频流播放，使用同一个workspace 管理

  音频软解编码部分依赖ffmpeg，只支持真机运行，故运行demo时请使用真机，不要使用模拟器。否则编译失败。

  运行截图：

  ![snapshot0](IMG_4552.png)

  ![snapshot](IMG_4551.png)下载地址：<https://testflight.top/t/IRZ3um> 

  appstore地址：

#### • 接口说明

##### 一、激活播放器 

CarEye_RtspActivate(key)

##### 二、创建句柄

CarEye_RtspCreate(*handle) 创建句柄 

##### 三、关联句柄和回调函数

CarEye_RtspEventRegister(CarEye_RTSP_Handle handle, RTSPSourceCallBack callback); 

 handle 由上一步获取，callback说明查看代码

typedef int (CE_APICALL *RTSPSourceCallBack)( int channelId, void *userPtr, CarEye_FrameFlag frameType, char *pBuf, CarEye_RtspFrameInfo* frameInfo);  的注释

rtsp 视频流将在下一步拉流开启后通过这个回调函数传过来。客户端主要关注 frameInfo 参数，即为获取到的音视频帧数据。

##### 四、开始拉流

CarEye_RtspStart(CarEye_RTSP_Handle handle, int channelId, char *url, 

​										CarEyeRtpConnectType connType, CarEye_FrameFlag mediaType, 

​										char *userName, char *password, void *userPtr, 

​										int reCount, int outRtpPacket, int heartbeatType, int verbosity);



传入上文注册好的并且关联好回调函数的句柄， 开始获取视频流数据。

##### 五、释放资源

关闭拉流 CarEye_RtspStop(CarEye_RTSP_Handle handle); 

释放句柄 CarEye_RtspRelease(CarEye_RTSP_Handle *handle);  



# 联系我们

car-eye 开源官方网址：www.car-eye.cn    

car-eye 流媒体平台网址：www.liveoss.com  

car-eye 技术官方邮箱: support@car-eye.cn

car-eye技术交流QQ群: 590411159        

![](https://github.com/Car-eye-team/Car-eye-server/blob/master/car-server/doc/QQ.jpg)  


CopyRight©  car-eye 开源团队 2018

