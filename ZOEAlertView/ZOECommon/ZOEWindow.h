//
//  ZOEAlertWindow.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/6/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZOEWindow : UIWindow
+ (instancetype)shareInstance;//控件父容器
+ (NSMutableArray *)shareStackArray;//控件存储
@end
