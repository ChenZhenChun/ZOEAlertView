//
//  ZOEAlertWindow.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/6/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEWindow.h"

@implementation ZOEWindow
static ZOEWindow *zoeWindow = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zoeWindow                 = [[ZOEWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
        zoeWindow.windowLevel     = UIWindowLevelAlert;
        zoeWindow.backgroundColor = [UIColor clearColor];
        //获取系统delegate创建的window，将delegate window 转变回keyWindow，这样确保在外部调用keyWindow时都是系统创建的那个window。
        UIWindow *window          = [[[UIApplication sharedApplication]delegate]window];
        [zoeWindow makeKeyAndVisible];
        [window makeKeyAndVisible];
    });
    return zoeWindow;
}

static NSMutableArray *stackArray = nil;
+ (NSMutableArray *)shareStackArray {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stackArray = [[NSMutableArray alloc] init];
    });
    return stackArray;
}

@end
