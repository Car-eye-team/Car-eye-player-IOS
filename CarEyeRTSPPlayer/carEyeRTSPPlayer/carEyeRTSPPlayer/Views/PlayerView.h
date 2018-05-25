//
//  PlayerView.h
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerView : UIView
@property (assign, nonatomic) BOOL audioPlaying;

- (void)renderWithURL:(NSString *)url;
@end
