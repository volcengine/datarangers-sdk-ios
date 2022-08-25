//
//  TableCellAction.h
//  Example
//
//  Created by SoulDiver on 2022/6/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TableCellActionStyle) {
    TableCellActionStyleDefault = 0,
    TableCellActionStyleSubtitle,
};

@interface TableCellAction : NSObject

@property (nonatomic, weak) UITableView *container;

@property (nullable, nonatomic, copy) NSString *title;

@property (nonatomic) TableCellActionStyle style;

@property (nullable, nonatomic, copy) void (^actionHandler)(TableCellAction *);

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(TableCellActionStyle)style handler:(void (^ __nullable)(TableCellAction *action))handler;


@property (nullable, nonatomic, copy) NSString *subtitle;

- (id)cellForTable:(UITableView *)table;

- (void)trigger;


@end

NS_ASSUME_NONNULL_END
