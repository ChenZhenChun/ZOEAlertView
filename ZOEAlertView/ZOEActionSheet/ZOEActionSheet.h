//
//  ZOEActionSheet.h
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/6/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZOEActionSheet : UIView
@property (nonatomic)        CGFloat            titleFontSize;//titleLabel font size,default is 18.
@property (nonatomic)        CGFloat            buttonFontSize;//uibutton font size,default is 18.
@property (nonatomic)        CGFloat            buttonHeight;//default is 50
@property (nonatomic,assign) CGFloat            scale;//界面缩放比例
@property (nonatomic,strong) UIColor            *titleTextColor;
@property (nonatomic,strong) UIColor            *buttonTextColor;
@property (nonatomic,readonly)NSInteger         cancelButtonIndex;
@property (nonatomic,assign) BOOL               disAble;//是否可被代码dismiss（不点击操作button）,default is Yes
@property (nonatomic,copy) NSString             *actionDescription;

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
 通过title添加Button
 
 @param title 按钮文本
 */
- (void)addButtonWithTitle:(NSString *)title;

/**
 移除所有ZOEAlertView（不会触发block回调）
 */
+ (void)dismissAllZOEActionSheet;

/**
 获取单前所有actionSheet
 
 @return AllActionSheet
 */
+ (NSArray *)getAllActionSheet;
@end
