//
//  PlayerViewController.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/4/26.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"
#import "CarEyeRTSPClientAPI.h"

@interface PlayerViewController ()
//@property (strong, nonatomic)  ;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CarEye_RtspActivate("6A59754D6A3469576B5A73414D433158714E4C4F6B76464659584E3555477868655756794C6D56345A536C58444661672F704C67523246326157346D516D466962334E68514449774D545A4659584E355247467964326C75564756686257566863336B3D");
    [self.playerView renderWithURL:@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
