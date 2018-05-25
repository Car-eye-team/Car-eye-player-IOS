
//
//  CarEyeAudioPlayer.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/5/20.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

typedef void (^CarEyeAudioPlayerOutputBlock)(SInt16 *outData, UInt32 numFrames, UInt32 numChannels);

@interface CarEyeAudioPlayer : NSObject
+ (CarEyeAudioPlayer *) sharedInstance;

@property (nonatomic, copy) CarEyeAudioPlayerOutputBlock outputBlock;

@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, weak) id source;
@property (nonatomic) float sampleRate;
@property (nonatomic) int channel;

- (BOOL) activateAudioSession;
- (void) deactivateAudioSession;

- (void)pause;
- (BOOL)play;
- (void)stop;
@end
