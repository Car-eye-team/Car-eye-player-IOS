//
//  RecordEntityListViewController.m
//  CarEyeRTMP
//
//  Created by xgh on 2018/8/26.
//  Copyright © 2018年 carEye. All rights reserved.
//

#import "RecordEntityListViewController.h"
#import "PathTool.h"
#import "RecordEntityCell.h"
#import "RecordPlayerViewController.h"

static NSString *reuseId = @"reuseId";
@interface RecordEntityListViewController ()
@property (strong, nonatomic) NSMutableArray *recordEntitys;
@end

@implementation RecordEntityListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView registerNib:[UINib nibWithNibName:@"RecordEntityCell" bundle:nil] forCellReuseIdentifier:reuseId];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat cellHeight = width *3/4.0; // 按3:4比例分配cell高度
    self.tableView.rowHeight = cellHeight;
}

- (NSMutableArray *)recordEntitys {
    if (_recordEntitys == nil) {
        _recordEntitys = [PathTool recordEntityWithUrl:self.url];
    }
    return _recordEntitys;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recordEntitys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecordEntityCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    RecordEntity *ent = self.recordEntitys[indexPath.row];
    cell.snapshot.image = [UIImage imageWithContentsOfFile:ent.snapshotPath];
    cell.filenameLabel.text = ent.videoName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RecordEntity *ent = self.recordEntitys[indexPath.row];
    RecordPlayerViewController *vc = [[RecordPlayerViewController alloc] init];
    vc.path = ent.videoPath;
    [self.navigationController pushViewController:vc animated:YES];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
