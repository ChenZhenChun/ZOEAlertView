//
//  MessageContentView.h
//  AiyoyouCocoapods
//  alertView 中间文字显示区域定义的view，今后中间区域的视图都在这个view定义
//  Created by aiyoyou on 2017/2/16.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZOEPlaceholderTextView.h"

/**
  PS:MessageContentView的宽度是一个固定值
  MessageContentView宽度 = （300-56）*_scale;
 _scale = ([UIScreen mainScreen].bounds.size.height>480?[UIScreen mainScreen].bounds.size.height/667.0:0.851574);
 */
@interface MessageContentView : UIScrollView
@property (nonatomic,strong) UILabel                    *messageLabel;
@property (nonatomic,strong) UITextField                *textField;
@property (nonatomic,strong) ZOEPlaceholderTextView     *textView;
@property (nonatomic,strong) NSMutableParagraphStyle    *paragraphStyle;
- (NSMutableAttributedString *)attrStrWithMessage:(NSString *)message;
@end
