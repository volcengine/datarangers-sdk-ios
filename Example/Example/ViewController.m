//
//  ViewController.m
//  Example
//
//  Created by SoulDiver on 2022/6/7.
//

#import "ViewController.h"
#import "TableCellAction.h"
#import "IdentifierViewController.h"

@import RangersAppLog;

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource> {
    UITableView *table;
    NSArray *actions;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"VOLCENGINE";
    // Do any additional setup after loading the view.
    actions = [self actionsInTable];
    
    
    
    
    table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    table.delegate = self;
    table.dataSource = self;
    [self.view addSubview:table];
    
    table.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":table}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":table}]];
    
    
    
}

- (NSArray *)actionsInTable
{
    return @[
        [TableCellAction actionWithTitle:@"Identifier" style:TableCellActionStyleDefault handler:^(TableCellAction * _Nonnull action) {
            [self.navigationController pushViewController:[IdentifierViewController new] animated:YES];
        }],
        [TableCellAction actionWithTitle:@"Profile" style:TableCellActionStyleDefault handler:^(TableCellAction * _Nonnull action) {
            
        }],
        [TableCellAction actionWithTitle:@"Event (random_event_${random_int})" style:TableCellActionStyleDefault handler:^(TableCellAction * _Nonnull action) {
            NSString *event = [NSString stringWithFormat:@"random_event_%d",arc4random_uniform(100)];
            [BDAutoTrack eventV3:event params:@{}];
        }],
        [TableCellAction actionWithTitle:@"Login (random uuid)" style:TableCellActionStyleDefault handler:^(TableCellAction * _Nonnull action) {
            [BDAutoTrack setCurrentUserUniqueID:[[NSUUID UUID] UUIDString]];
        }],
        [TableCellAction actionWithTitle:@"Logout" style:TableCellActionStyleDefault handler:^(TableCellAction * _Nonnull action) {
            [BDAutoTrack clearUserUniqueID];
        }],
    ];
}

#pragma mark -


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    TableCellAction *action = [actions objectAtIndex:indexPath.item];
    return [action cellForTable:tableView];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [actions count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TableCellAction *action = [actions objectAtIndex:indexPath.item];
    [action trigger];
}



@end
