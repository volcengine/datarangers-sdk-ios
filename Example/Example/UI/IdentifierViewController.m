//
//  IdentifierViewController.m
//  Example
//
//  Created by SoulDiver on 2022/6/15.
//

#import "IdentifierViewController.h"
#import "TableCellAction.h"

@import RangersAppLog;

@interface IdentifierViewController ()

@end

@implementation IdentifierViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Identifier";
    // Do any additional setup after loading the view.
}

- (NSArray *)actionsInTable
{
    
    TableCellAction *did = [TableCellAction new];
    did.title = @"deviceID";
    did.subtitle = [[BDAutoTrack sharedTrack] rangersDeviceID];
    did.style = TableCellActionStyleSubtitle;
    
    TableCellAction *iid = [TableCellAction new];
    iid.title = @"installID";
    iid.subtitle = [[BDAutoTrack sharedTrack] installID];
    iid.style = TableCellActionStyleSubtitle;
    
    TableCellAction *ssid = [TableCellAction new];
    ssid.title = @"ssID";
    ssid.subtitle = [[BDAutoTrack sharedTrack] ssID];
    ssid.style = TableCellActionStyleSubtitle;
    
    TableCellAction *userId = [TableCellAction new];
    userId.title = @"UserUniqueId";
    userId.subtitle = [[BDAutoTrack sharedTrack] userUniqueID];
    userId.style = TableCellActionStyleSubtitle;
    
    return @[did,iid,ssid,userId];
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
