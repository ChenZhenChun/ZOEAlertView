//
//  ZOEAlertView.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageContentView.h"

typedef NS_ENUM(NSInteger, ZOEAlertViewStyle) {
    ZOEAlertViewStyleDefault = 0,
    ZOEAlertViewStyleSecureTextInput,
    ZOEAlertViewStylePlainTextInput
};

@class ZOEAlertView;

/**
 alertView中的MessageContentView区域是可以高度定制的（如果不自定义默认情况下有三种模板ZOEAlertViewStyle）；
 ZOEAlertView通过代理的形式将MessageContentView区域委托出去
 代理对象只要通过heightForMessageContentView协议设置MessageContentView的高度，
 通过messageContentViewWithZOEAlertView协议设置MessageContentView的实例，就可以对MessageContentView
 实现自定义
 调用handleKeyboard:方法可以解决自定义MessageContentView中输入框被键盘遮挡的问题。
     _______________________
    |         title         |
    |_______________________|
    | _____________________ |
    ||                     ||
    ||                     ||
    ||                     ||
    || MessageContentView  ||
    ||                     ||
    ||                     ||
    ||_____________________||
    |_______________________|
    |           |           |
    |   cancel  |    OK     |
    |___________|___________|

 */
@protocol ZOEAlertViewDelegate <NSObject>
@optional
- (CGFloat)heightForMessageContentView;//自定messageContentView的高度；
- (MessageContentView *)messageContentViewWithZOEAlertView:(ZOEAlertView *)alertView;//获取messageContentView实例；
@end

@interface ZOEAlertView : UIView
@property (nonatomic,readonly) UIView               *alertContentView;
@property (nonatomic,readonly) UILabel              *titleLabel;
@property (nonatomic,readonly) MessageContentView   *messageContentView;
@property (nonatomic)        CGFloat                lineSpacing;//message lineSpacing,default is 5.
@property (nonatomic)        CGFloat                titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat                messageFontSize;//messageLabel font size,default is 15.
@property (nonatomic)        CGFloat                buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic,strong) UIColor                *titleTextColor;
@property (nonatomic,strong) UIColor                *messageTextColor;
@property (nonatomic,strong) UIColor                *buttonTextColor;
@property (nonatomic,readonly)NSInteger             cancelButtonIndex;
@property (nonatomic)        NSTextAlignment        messageTextAlignment;//messageLabel TextAlignment,default is NSTextAlignmentCenter
@property (nonatomic,assign) ZOEAlertViewStyle      alertViewStyle;
@property (nonatomic,copy)   NSString               *textFieldPlaceholder;
@property (nonatomic,assign) BOOL                   disAble;//是否可被代码dismiss（不点击操作button）,default is Yes
@property (nonatomic,readonly)UITextField           *textField;

//这个代理不是必须要设置的，只有MessageContentView区域需要自定义时才需要设置。
@property (nonatomic,assign) id<ZOEAlertViewDelegate> delegate;

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
//设置按钮颜色(如果是用addButtonWithTitle添加的按钮，颜色只能放在showWithBlock后面)
- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex;

/**
 通过title添加Button
 
 @param title 按钮文本
 */
- (void)addButtonWithTitle:(NSString *)title;

/**
 处理键盘遮挡输入框的问题
 @param textFieldOrTextView UITextField 或 UITextView
 */
- (void)handleKeyboard:(UIView *)textFieldOrTextView;

/**
 展示提示性信息

 @param message 提示文本
 */
- (void)showTipViewWithMessage:(NSString *)message;

/**
 移除所有ZOEAlertView（不会触发block回调）
 */
+ (void)dismissAllZOEAlertView;

- (void)configFrame;

@end
