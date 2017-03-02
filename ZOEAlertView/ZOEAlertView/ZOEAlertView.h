//
//  ZOEAlertView.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ZOEAlertViewStyle) {
    ZOEAlertViewStyleDefault = 0,
    ZOEAlertViewStyleSecureTextInput,
    ZOEAlertViewStylePlainTextInput
};

@interface ZOEAlertView : UIView

@property (nonatomic)        CGFloat            lineSpacing;//message lineSpacing,default is 5.
@property (nonatomic)        CGFloat            titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat            messageFontSize;//messageLabel font size,default is 15.
@property (nonatomic)        CGFloat            buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic,strong) UIColor            *titleTextColor;
@property (nonatomic,strong) UIColor            *messageTextColor;
@property (nonatomic,strong) UIColor            *buttonTextColor;
@property (nonatomic,readonly)NSInteger         cancelButtonIndex;
@property (nonatomic)        NSTextAlignment    messageTextAlignment;//messageLabel TextAlignment,default is NSTextAlignmentCenter
@property (nonatomic,assign) ZOEAlertViewStyle  alertViewStyle;
@property (nonatomic,copy)   NSString           *textFieldPlaceholder;
@property (nonatomic,assign) BOOL               disAble;//是否可被代码dismiss（不点击操作button）,default is Yes
@property (nonatomic,readonly)UITextField       *textField;

- (instancetype)initWithTitle:(NSString*)title message:(NSString*)message cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)showWithBlock:(void(^)(NSInteger buttonIndex))block;

- (void)showWithBlock:(void(^)(NSInteger buttonIndex))block animated:(BOOL)animated;

/**
 移除当前的alertView（不会触发block回调）
 */
- (void)dismissZOEAlertView;

/**
 alertView是否可以dismiss(满足点击按钮去执行一些验证操作，最终通过Block返回值判断是否需要dismiss控件😂)

 @param shouldDisBlock 回调
 */

- (void)shouldDismissWithBlock:(BOOL(^)(NSInteger buttonIndex))shouldDisBlock;//buttonIndex = -1. Did not click on the button.

/**
 alertView已经消失

 @param didDisBlock 回调
 */
- (void)didDismissWithBlock:(void(^)(NSInteger buttonIndex))didDisBlock;//buttonIndex = -1. Did not click on the button.

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







@interface ZOEActionSheet : UIView
@property (nonatomic)        CGFloat            titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat            buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic,strong) UIColor            *titleTextColor;
@property (nonatomic,strong) UIColor            *buttonTextColor;
@property (nonatomic,readonly)NSInteger         cancelButtonIndex;
@property (nonatomic,assign) BOOL               disAble;//是否可被代码dismiss（不点击操作button）,default is Yes

- (instancetype)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)showWithBlock:(void(^)(NSInteger buttonIndex))block;

/**
 移除当前的alertView（不会触发block回调）
 */
- (void)dismissZOEActionSheet;

/**
 根据buttonIndex 设置button文字颜色
 
 @param color  文字颜色
 @param buttonIndex 按钮索引，cancelButtonIndex=0 otherButtonTitles以此类推
 */
- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex;

/**
 移除所有ZOEAlertView（不会触发block回调）
 */
+ (void)dismissAllZOEActionSheet;
@end
