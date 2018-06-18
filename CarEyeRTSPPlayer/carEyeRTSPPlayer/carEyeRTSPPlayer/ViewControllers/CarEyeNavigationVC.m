//
//  CarEyeNavigationVC.m
//  carEyeRTSPPlayer
//
//  Created by xgh on 2018/7/6.
//  Copyright © 2018年 car-eye. All rights reserved.
//

#import "CarEyeNavigationVC.h"

@interface CarEyeNavigationVC ()

@end

@implementation CarEyeNavigationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
    
}

- (BOOL)shouldAutorotate{
    
    return [[self.viewControllers lastObject] shouldAutorotate];
    
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
