//
//  TableCellAction.m
//  Example
//
//  Created by SoulDiver on 2022/6/15.
//

#import "TableCellAction.h"

@interface TableCellAction ()


@end

@implementation TableCellAction


+ (instancetype)actionWithTitle:(nullable NSString *)title style:(TableCellActionStyle)style handler:(void (^ __nullable)(TableCellAction *action))handler
{
    TableCellAction *action = [TableCellAction new];
    action.title = title;
    action.style = style;
    action.actionHandler = [handler copy];
    return action;
}

- (void)trigger
{
    if (self.actionHandler) {
        self.actionHandler(self);
    }
}

- (NSString *)reuseCellIdentifier
{
    switch (self.style) {
        case TableCellActionStyleDefault:
            return @"TableCellActionStyleDefault";
        case TableCellActionStyleSubtitle:
            return @"TableCellActionStyleSubtitle";
        default:
            return @"TableCellActionStyleDefault";
    }
}


- (id)cellForTable:(UITableView *)table
{
    if (!table || ![table isKindOfClass:UITableView.class]) {
        return nil;
    }
    NSString *identifier = [self reuseCellIdentifier];
    UITableViewCell * cell = [table dequeueReusableCellWithIdentifier:identifier];
    switch (self.style) {
        case TableCellActionStyleSubtitle: {
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            }
            cell.textLabel.text = self.title;
            cell.detailTextLabel.text = self.subtitle;
            break;
        }
            
            
        default: {
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            cell.textLabel.text = self.title;
            break;
        }
            
    }
    return cell;
}

@end
