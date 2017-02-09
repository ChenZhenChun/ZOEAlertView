//
//  ZOEAlertView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEAlertView.h"
#import <objc/runtime.h>


#define kBtnH (56*self.scale)
#define kalertViewW (300*self.scale)

//默认属性参数
#define klineSpacing                (5*self.scale)
#define ktitleFontSize              (18*self.scale)
#define kmessageFontSize            (15*self.scale)
#define kbuttonFontSize             (18*self.scale)
#define ktitleTextColor             [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1]
#define kmessageTextColor           [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1]
#define kcancelButtonTextColor      [UIColor colorWithRed:0 green:162/255.0 blue:1 alpha:1]
#define koKButtonTitleTextColor     [UIColor colorWithRed:0 green:162/255.0 blue:1 alpha:1]


static NSMutableArray *alertViewArray;
@interface ZOEAlertView()
@property (nonatomic,strong) UIView         *alertContentView;
@property (nonatomic,strong) UILabel        *titleLabel;
@property (nonatomic,strong) UILabel        *messageLabel;
@property (nonatomic,strong) UIView         *line1;
@property (nonatomic,strong) UIView         *line2;
@property (nonatomic,strong) UIButton       *leftBtn;
@property (nonatomic,strong) UIButton       *rightBtn;
@property (nonatomic)        CGFloat        scale;
@property (nonatomic,copy) void(^MyBlock)(NSInteger buttonIndex);
@property (nonatomic,strong) NSMutableParagraphStyle *paragraphStyle;

@end

@implementation ZOEAlertView
@synthesize lineSpacing             = _lineSpacing;
@synthesize titleFontSize           = _titleFontSize;
@synthesize messageFontSize         = _messageFontSize;
@synthesize buttonFontSize          = _buttonFontSize;
@synthesize titleTextColor          = _titleTextColor;
@synthesize messageTextColor        = _messageTextColor;
@synthesize cancelButtonTextColor   = _cancelButtonTextColor;
@synthesize oKButtonTitleTextColor  = _oKButtonTitleTextColor;


//初始化
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle oKButtonTitle:(NSString *)okButtonTitle {
    self = [super init];
    if (self) {
        //默认参数初始化
        self.backgroundColor    = [UIColor colorWithWhite:0 alpha:0.7];
        self.frame              = [UIScreen mainScreen].bounds;
        _lineSpacing            = klineSpacing;
        _titleFontSize          = ktitleFontSize;
        _messageFontSize        = kmessageFontSize;
        _buttonFontSize         = kbuttonFontSize;
        _titleTextColor         = ktitleTextColor;
        _messageTextColor       = kmessageTextColor;
        _cancelButtonTextColor  = kcancelButtonTextColor;
        _oKButtonTitleTextColor = koKButtonTitleTextColor;
        _cancelButtonIndex = 0;
        _okButtonIndex = 1;
        
        //将alertView存储在静态数组中
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            alertViewArray = [[NSMutableArray alloc]init];
        });
        [alertViewArray addObject:self];
        
        //添加子控件
        [self addSubview:self.alertContentView];
        [self.alertContentView addSubview:self.line1];
        //添加titleLabel
        if (title&&title.length>0) {
            [self.alertContentView addSubview:self.titleLabel];
            self.titleLabel.text = title;
        }
        //添加消息详细Label
        if (message&&message.length>0) {
            [self.alertContentView addSubview:self.messageLabel];
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:message];
            //调整行间距
            self.paragraphStyle.lineSpacing = self.lineSpacing*self.scale;
            [attrStr addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:NSMakeRange(0, attrStr.string.length)];
            self.messageLabel.attributedText = attrStr;
        }
        
        //添加左边的按钮（取消按钮）
        if (cancelButtonTitle&&cancelButtonTitle.length>0) {
            [self.alertContentView addSubview:self.leftBtn];
            [self.leftBtn setTitle:cancelButtonTitle forState:UIControlStateNormal];
        }
        //添加游标的按钮（确定按钮）
        if (okButtonTitle&&okButtonTitle.length>0) {
            [self.alertContentView addSubview:self.rightBtn];
            [self.rightBtn setTitle:okButtonTitle forState:UIControlStateNormal];
        }
    }
    return self;
}

//展示控件
- (void)showWithBlock:(void (^)(NSInteger))Block {
    _MyBlock = Block;
    if (_leftBtn || _rightBtn) {
        [self configFrame];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];
        [window endEditing:YES];
        if (alertViewArray.count-1>0) {
            ZOEAlertView *alertView = alertViewArray[alertViewArray.count-2];
            alertView.hidden = YES;
        }
    }
}

//动态配置子控件的位置及大小
- (void)configFrame {
    //必须至少有一个操作按钮才能展现控件
    if (_leftBtn || _rightBtn) {
        CGFloat alertViewH = kBtnH+21*self.scale;//底部按钮操作区域高度+21点的空白
        if (_titleLabel) {
            alertViewH += (21+_titleLabel.font.pointSize)*self.scale;
            _titleLabel.frame = CGRectMake(15*self.scale,21*self.scale,kalertViewW-30*self.scale,_titleLabel.font.pointSize*self.scale);
        }
        if (_messageLabel) {
            CGFloat y = 28*self.scale;
            if (_titleLabel) {
                y = (21+_titleLabel.font.pointSize+28)*self.scale;
            }
            _messageLabel.frame = CGRectMake(28*self.scale,y,kalertViewW-56*self.scale,0);
            [_messageLabel sizeToFit];
            if (_messageLabel.frame.size.height>self.frame.size.height-200) {
                _messageLabel.frame = CGRectMake(28*self.scale,y,kalertViewW-56*self.scale,self.frame.size.height-200);
            }else {
                _messageLabel.frame = CGRectMake(28*self.scale,y,kalertViewW-56*self.scale,_messageLabel.frame.size.height);
            }
            //使用sizeToFit之后对齐方式失效，
            _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            _messageLabel.textAlignment = NSTextAlignmentCenter;
            
            alertViewH += 28*self.scale+_messageLabel.frame.size.height;
        }
        _line1.frame = CGRectMake(0,alertViewH-kBtnH,kalertViewW,0.5);
        
        //两个按钮的位置
        if (_leftBtn&&_rightBtn) {
            _leftBtn.frame = CGRectMake(0,alertViewH-kBtnH,kalertViewW/2.0,kBtnH);
            [self.alertContentView addSubview:self.line2];
            _line2.frame = CGRectMake(kalertViewW/2.0,alertViewH-kBtnH,0.5,kBtnH);
            _rightBtn.frame = CGRectMake(kalertViewW/2.0,alertViewH-kBtnH,kalertViewW/2.0,kBtnH);
        }else {
            UIButton *button = _leftBtn?_leftBtn:_rightBtn;
            button.frame = CGRectMake(0,alertViewH-kBtnH,kalertViewW,kBtnH);
        }
        _alertContentView.frame = CGRectMake(0,0,kalertViewW,alertViewH);
        self.alertContentView.center = self.center;
    }
}

//操作按钮点击事件
- (void)clickButton:(UIButton *)sender {
    if (_MyBlock) {
        _MyBlock(sender.tag);
    }
    [self removeFromSuperview];
}

//重写父类方法(移除当前ZOEAlertView的同时将上一个ZOEAlertView显示出来)
- (void)removeFromSuperview {
    [super removeFromSuperview];
    if (alertViewArray.count>0) {
        ZOEAlertView *alertView = alertViewArray[alertViewArray.count-1];
        [alertViewArray removeObject:alertView];
    }
    if (alertViewArray.count>0) {
        ZOEAlertView *alertView = alertViewArray[alertViewArray.count-1];
        alertView.hidden = NO;
    }
}

//移除当前的alertView（不会触发block回调）
- (void)dismissZOEAlertView {
    [self removeFromSuperview];
}

//移除所有ZOEAlertView（不会触发block回调）
+ (void)dismissAllZOEAlertView {
    while(alertViewArray.count) {
        ZOEAlertView *alertView = alertViewArray[alertViewArray.count-1];
        [alertView removeFromSuperview];
    }
}

#pragma mark - init

//alertView内容父容器
- (UIView *)alertContentView {
    if (!_alertContentView) {
        _alertContentView = [[UIView alloc]init];
        _alertContentView.clipsToBounds = YES;
        _alertContentView.layer.cornerRadius = 10*self.scale;
        _alertContentView.backgroundColor = [UIColor whiteColor];
    }
    return _alertContentView;
}

//title
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:_titleFontSize];
        _titleLabel.textColor = self.titleTextColor;
    }
    return _titleLabel;
}
//消息详细
- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc]init];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.font = [UIFont systemFontOfSize:_messageFontSize];
        _messageLabel.numberOfLines = 0;
        _messageLabel.textColor = self.messageTextColor;
    }
    return _messageLabel;
}
//左边的操作按钮
- (UIButton *)leftBtn {
    if (!_leftBtn) {
        _leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBtn setTitleColor:self.cancelButtonTextColor forState:UIControlStateNormal];
        [_leftBtn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
        _leftBtn.tag = _cancelButtonIndex;
        _leftBtn.backgroundColor = [UIColor clearColor];
        [_leftBtn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBtn;
}
//右边的操作按钮
- (UIButton *)rightBtn {
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
        [_rightBtn setTitleColor:self.oKButtonTitleTextColor forState:UIControlStateNormal];
        _rightBtn.tag = _okButtonIndex;
        _rightBtn.backgroundColor = [UIColor clearColor];
        [_rightBtn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightBtn;
}
//分割线
- (UIView *)line1 {
    if (!_line1) {
        _line1 = [[UIView alloc]init];
        _line1.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
    }
    return _line1;
}
//两个按钮间的分割线
- (UIView *)line2 {
    if (!_line2) {
        _line2 = [[UIView alloc]init];
        _line2.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
    }
    return _line2;
}
//屏幕比例
- (CGFloat)scale {
    if (_scale == 0) {
        _scale = ([UIScreen mainScreen].bounds.size.height>480?[UIScreen mainScreen].bounds.size.height/667.0:0.851574);
    }
    return _scale;
}

- (NSMutableParagraphStyle *)paragraphStyle {
    if (!_paragraphStyle) {
        _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    }
    return _paragraphStyle;
}

#pragma mark - setter方法设置属性
//行高设置
- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
    self.paragraphStyle.lineSpacing = _lineSpacing*self.scale;
    [self configFrame];
}

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    if (_titleLabel) {
        _titleFontSize = titleFontSize;
        _titleLabel.font = [UIFont systemFontOfSize:_titleFontSize*self.scale];
        [self configFrame];
    }
}

- (void)setMessageFontSize:(CGFloat)messageFontSize {
    if (_messageLabel) {
        _messageFontSize = messageFontSize;
        _messageLabel.font = [UIFont systemFontOfSize:_messageFontSize*self.scale];
        [self configFrame];
    }
}

- (void)setButtonFontSize:(CGFloat)buttonFontSize {
    if (_leftBtn) {
        _buttonFontSize = buttonFontSize;
        [_leftBtn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize*self.scale]];
    }
    if (_rightBtn) {
        _buttonFontSize = buttonFontSize;
        [_rightBtn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize*self.scale]];
    }
    if (_buttonFontSize != 18*self.scale)[self configFrame];
}

- (void)setTitleTextColor:(UIColor *)titleTextColor {
    if (_titleLabel) {
        _titleTextColor = titleTextColor;
        _titleLabel.textColor = _titleTextColor;
    }
}

- (void)setMessageTextColor:(UIColor *)messageTextColor {
    if (_messageLabel) {
        _messageTextColor = messageTextColor;
        _messageLabel.textColor = _messageTextColor;
    }
}

- (void)setCancelButtonTextColor:(UIColor *)cancelButtonTextColor {
    if (_leftBtn) {
        _cancelButtonTextColor = cancelButtonTextColor;
       [_leftBtn setTitleColor:_cancelButtonTextColor forState:UIControlStateNormal];
    }
}

- (void)setOKButtonTitleTextColor:(UIColor *)oKButtonTitleTextColor {
    if (_rightBtn) {
        _oKButtonTitleTextColor = oKButtonTitleTextColor;
        [_rightBtn setTitleColor:_oKButtonTitleTextColor forState:UIControlStateNormal];
    }
}



@end
