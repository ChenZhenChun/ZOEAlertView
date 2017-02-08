//
//  ZOEAlertView.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZOEAlertView : UIView
@property (nonatomic)        CGFloat        lineSpacing;//message lineSpacing,default is 5.
@property (nonatomic)        CGFloat        titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat        messageFontSize;//messageLabel font size,default is 15.
@property (nonatomic)        CGFloat        buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic,strong) UIColor        *titleTextColor;
@property (nonatomic,strong) UIColor        *messageTextColor;
@property (nonatomic,strong) UIColor        *cancelButtonTextColor;
@property (nonatomic,strong) UIColor        *oKButtonTitleTextColor;
@property (nonatomic,readonly)NSInteger     cancelButtonIndex;
@property (nonatomic,readonly)NSInteger     okButtonIndex;


- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle oKButtonTitle:(NSString *)okButtonTitle;
- (void)showWithBlock:(void(^)(NSInteger buttonIndex))Block;
@end
