//
//  CarEyePlayerView.h
//  CarEyeRTMP
//
//  Created by xgh on 2018/7/28.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger,CarEyePlayerViewState){
    CarEyePlayViewStateSmall,
    CarEyePlayViewStateAnimating,
    CarEyePlayViewStateFullscreen,

};
@protocol CarEyePlayerViewDelegate;
@interface CarEyePlayerView : UIView
@property (weak, nonatomic) id<CarEyePlayerViewDelegate> delegate;
@property (assign, nonatomic) CarEyePlayerViewState state;
@property (assign, nonatomic, readonly) CGRect frameBeforeFull;


- (void)playerUrl:(NSString *)url;
- (void)stop;
- (void)pause;
@end

@protocol CarEyePlayerViewDelegate <NSObject>
- (void)carEyePlayerView:(CarEyePlayerView *)view didClickAdd:(UIButton *)btn;
- (void)carEyePlayerView:(CarEyePlayerView *)view didClickToFull:(BOOL)goFulling;
@end
