//
//  NSMutableDictionary+BDAutoTrackParameter.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/30.
//  Copyright 2022 Beijing Volcanoengine Technology Ltd. All Rights Reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (BDAutoTrackParameter)

//转换非法Key
// e.g.
//$user_unique_id_type => user_unique_id_type
- (void)bdheader_keyFormat;

@end

NS_ASSUME_NONNULL_END
