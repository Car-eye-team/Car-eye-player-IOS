//
//  KxMovieDecoder.m
//  kxmovie
//
//  Created by Kolyvan on 15.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "KxMovieDecoder.h"
#import <Accelerate/Accelerate.h>

NSString * kxmovieErrorDomain = @"ru.kolyvan.kxmovie";

@interface KxMovieFrame()

@end

@implementation KxMovieFrame

@end

@interface KxAudioFrame()

@end

@implementation KxAudioFrame

- (KxMovieFrameType) type { return KxMovieFrameTypeAudio; }

@end

@interface KxVideoFrame()

@end

@implementation KxVideoFrame
- (KxMovieFrameType) type { return KxMovieFrameTypeVideo; }
@end

@interface KxVideoFrameRGB ()
@end

@implementation KxVideoFrameRGB

- (KxVideoFrameFormat) format {
    return KxVideoFrameFormatRGB;
}

- (UIImage *) asImage {
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}

@end

@interface KxVideoFrameYUV()

@end

@implementation KxVideoFrameYUV

- (KxVideoFrameFormat) format {
    return KxVideoFrameFormatYUV;
}


@end
