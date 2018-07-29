//
//  UIDevice+CarEyeOrientation.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/7/28.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "UIDevice+CarEyeOrientation.h"

@implementation UIDevice (CarEyeOrientation)
+(void)switchOrientation:(UIInterfaceOrientation)newInterfaceOrienttation {
    NSNumber *unknownOrientation = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    [[UIDevice currentDevice] setValue:unknownOrientation forKey:@"orientation"];
    NSNumber *newOrientation = [NSNumber numberWithInt:newInterfaceOrienttation];
    [[UIDevice currentDevice] setValue:newOrientation forKey:@"orientation"];
}
@end
