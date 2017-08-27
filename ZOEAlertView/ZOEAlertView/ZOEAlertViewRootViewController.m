//
//  ZOEAlertViewRootViewController.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/8/27.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEAlertViewRootViewController.h"

@interface ZOEAlertViewRootViewController ()

@end

@implementation ZOEAlertViewRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//是否支持旋转屏幕
- (BOOL)shouldAutorotate {
    return YES;
}
//设备支持的方向
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft;
}
//当前控制器默认的方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - 判断设备方向
- (BOOL)isDeviceOrientationPortrait{
    UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
    return o == UIInterfaceOrientationPortrait;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (UIView *view in self.view.subviews) {
        view.frame = self.view.bounds;
        if ([view isKindOfClass:NSClassFromString(@"ZOEAlertView")]) {
            UIView *contentView = [view valueForKey:@"alertContentView"];
            contentView.center = self.view.center;
        }else if ([view isKindOfClass:NSClassFromString(@"ZOEActionSheet")]) {
            [view layoutSubviews];
        }
    }
//    if ([self isDeviceOrientationPortrait]) {
//        //竖屏
//        NSLog(@"现在是竖屏");
//    } else {
//        //横屏
//        NSLog(@"现在是横屏");
//    }
}

@end
