//
//  MessageContentView.h
//  AiyoyouCocoapods
//  alertView 中间文字显示区域定义的view，今后中间区域的视图都在这个view定义
//  Created by aiyoyou on 2017/2/16.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageContentView : UIView
@property (nonatomic,strong) UILabel                    *messageLabel;
@property (nonatomic,strong) NSMutableParagraphStyle    *paragraphStyle;
@property (nonatomic,strong) NSMutableAttributedString  *attrStr;
- (NSMutableAttributedString *)attrStrWithMessage:(NSString *)message;
@end
