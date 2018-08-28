//
//  RecordEntity.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/26.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "RecordEntity.h"
#import "PathTool.h"
@implementation RecordEntity
- (instancetype)initWithUrl:(NSString *)url {
    if (self = [super init]) {
        _url = url;
    }
    return self;
}
@end
