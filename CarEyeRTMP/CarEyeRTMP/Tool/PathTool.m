//
//  PathTool.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/21.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "PathTool.h"
static NSString *recordList = @"recordList";
@implementation PathTool

+ (NSString *)getVideoDirWithUrl:(NSString *)url {
    NSString * videoDir = [[self recordDir:url] stringByAppendingPathComponent:@"video"];
    videoDir = [[self getDocumentDir] stringByAppendingPathComponent:videoDir];
    if(![[NSFileManager defaultManager] fileExistsAtPath:videoDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:videoDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoDir;
}
+ (NSString *)getSnapshotDirWithUrl:(NSString *)url {
    NSString *snapshot = [[self recordDir:url] stringByAppendingPathComponent:@"snapshot"];
    snapshot = [[self getDocumentDir] stringByAppendingPathComponent:snapshot];
    if(![[NSFileManager defaultManager] fileExistsAtPath:snapshot]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:snapshot withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return snapshot;
}
+ (NSString *)getDocumentDir {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}
+ (NSString *)recordDir:(NSString *)url {
    NSString *addr = [url stringByReplacingOccurrencesOfString:@"/" withString:@""];
    addr = [addr stringByReplacingOccurrencesOfString:@":" withString:@""];
    addr = [addr stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *recordDir = [[self getDocumentDir] stringByAppendingString:addr];
    if(![[NSFileManager defaultManager] fileExistsAtPath:recordDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:recordDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSMutableArray *urls = [self recordUrls];
        [urls addObject:url];
        [self updateRecordList:urls];
    }
    return addr;
}

+ (RecordEntity *)entityWithUrl:(NSString *)url {
    RecordEntity *ent = [[RecordEntity alloc] initWithUrl:url];
    NSString *videoDir = [self getVideoDirWithUrl:url];
    NSString *snapshotDir = [self getSnapshotDirWithUrl:url];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMddhhmmss"];
    NSString *dateStr = [formatter stringFromDate:date];
    NSString *videoPath = [videoDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",dateStr]];
    NSString *snapShotPath = [snapshotDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",dateStr]];
    ent.videoPath = videoPath;
    ent.snapshotPath = snapShotPath;
    return ent;
}

+ (NSMutableArray <NSString *> *)recordUrls {
    NSMutableArray *urls = [[NSUserDefaults standardUserDefaults] objectForKey:recordList];
    if (urls == nil) {
        urls = [NSMutableArray array];
    }
    return urls;
}
+ (void)updateRecordList:(NSArray <NSString *> *)newList {
    [[NSUserDefaults standardUserDefaults] setObject:newList forKey:recordList];
}
// 某个url下的所有视频文件
+ (NSArray *) videoListWithUrl:(NSString *)url {
    
    NSArray *fileNameList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getVideoDirWithUrl:url] error:nil];
    return fileNameList;
}
+ (NSMutableArray <RecordEntity *>*)recordEntityWithUrl:(NSString *)url {
    NSArray *videoNames = [self videoListWithUrl:url];
    NSMutableArray *entities = [NSMutableArray array];
    if (videoNames) {
        for (int i = 0; i< videoNames.count; i++) {
            RecordEntity *ent = [[RecordEntity alloc] initWithUrl:url];
            NSString *filename = videoNames[i];
            ent.videoName = filename;
            ent.videoPath = [[self getVideoDirWithUrl:url] stringByAppendingPathComponent:filename];
            NSString *snapshot = [filename stringByReplacingOccurrencesOfString:@"mp4" withString:@"png"];
            ent.snapshotPath = [[self getSnapshotDirWithUrl:url] stringByAppendingPathComponent:snapshot];
            [entities addObject:ent];
        }
    }
    return entities;
}
@end
