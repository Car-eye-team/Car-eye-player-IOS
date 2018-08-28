//
//  RecordEntityCell.h
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/28.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordEntityCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *snapshot;
@property (weak, nonatomic) IBOutlet UILabel *filenameLabel;

@end

NS_ASSUME_NONNULL_END
