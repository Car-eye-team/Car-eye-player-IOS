//
//  PathTool.h
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/21.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecordEntity.h"
@interface PathTool : NSObject
+ (RecordEntity *)entityWithUrl:(NSString *)url;
+ (NSMutableArray <NSString *> *)recordUrls;
+ (NSMutableArray <RecordEntity *>*)recordEntityWithUrl:(NSString *)url;
@end
