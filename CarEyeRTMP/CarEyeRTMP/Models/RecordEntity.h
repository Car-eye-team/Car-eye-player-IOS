//
//  RecordEntity.h
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/26.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordEntity : NSObject
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *snapshotPath;
@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *dirName;
@property (nonatomic, copy) NSString *videoName;


- (instancetype)initWithUrl:(NSString *)url;
@end
