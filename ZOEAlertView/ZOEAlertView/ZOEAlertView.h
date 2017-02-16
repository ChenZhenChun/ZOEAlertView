//
//  ZOEAlertView.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZOEAlertView : UIView

@property (nonatomic)        CGFloat            lineSpacing;//message lineSpacing,default is 5.
@property (nonatomic)        CGFloat            titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat            messageFontSize;//messageLabel font size,default is 15.
@property (nonatomic)        CGFloat            buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic,strong) UIColor            *titleTextColor;
@property (nonatomic,strong) UIColor            *messageTextColor;
@property (nonatomic,strong) UIColor            *buttonTextColor;
@property (nonatomic,readonly)NSInteger         cancelButtonIndex;
@property(nonatomic)         NSTextAlignment    messageTextAlignment;//messageLabel TextAlignment,default is NSTextAlignmentCenter

- (instancetype)initWithTitle:(NSString*)title message:(NSString*)message cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;


- (void)showWithBlock:(void(^)(NSInteger buttonIndex))Block;

/**
 移除当前的alertView（不会触发block回调）
 */
- (void)dismissZOEAlertView;


/**
 根据buttonIndex 设置button文字颜色

 @param color  文字颜色
 @param buttonIndex 按钮索引，cancelButtonIndex=0 otherButtonTitles以此类推
 */
- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex;

/**
 移除所有ZOEAlertView（不会触发block回调）
 */
+ (void)dismissAllZOEAlertView;
@end
