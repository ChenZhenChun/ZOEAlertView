//
//  ZOECommonHead.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/6/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZOEWindow.h"

#define kBtnH (45*_scale)
#define kBtnTagAppend 200  //tag从0开始容易和默认的tag冲突，所以额外累加一个参数
#define ktitleFontSize              (16)
#define kbuttonFontSize             (15)
#define ktitleTextColor             [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1]
#define kbuttonTextColor            [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1]

typedef NS_ENUM(NSInteger, ZOEStyle) {
    ZOEAlertViewStyleAlert = 0,
    ZOEAlertViewStyleActionSheet
} ;
