//
//  ZOEAlertView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEAlertView.h"
#import "MessageContentView.h"

#define kBtnH (56*_scale)
#define kalertViewW (300*_scale)
#define kBtnTagAppend 200  //tag从0开始容易和默认的tag冲突，所以额外累加一个参数

//默认属性参数
#define klineSpacing                (5*_scale)
#define ktitleFontSize              (18*_scale)
#define kmessageFontSize            (15*_scale)
#define kbuttonFontSize             (18*_scale)
#define ktitleTextColor             [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1]
#define kmessageTextColor           [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1]
#define kbuttonTextColor            [UIColor colorWithRed:0 green:162/255.0 blue:1 alpha:1]
#define koKButtonTitleTextColor     [UIColor colorWithRed:0 green:162/255.0 blue:1 alpha:1]


static NSMutableArray                                   *alertViewArray;
static UIWindow                                         *alertWindow;
@interface ZOEAlertView()
@property (nonatomic)        CGFloat                    scale;
@property (nonatomic,strong) UIView                     *alertContentView;
@property (nonatomic,strong) UILabel                    *titleLabel;
@property (nonatomic,strong) MessageContentView         *messageContentView;
@property (nonatomic,strong) UIView                     *operationalView;

@property (nonatomic,copy)   NSString                   *title;
@property (nonatomic,copy)   NSString                   *message;
@property (nonatomic,copy)   NSString                   *cancelButtonTitle;
@property (nonatomic,strong) NSMutableArray             *otherButtonTitles;
@property (nonatomic,copy) void(^MyBlock)(NSInteger buttonIndex);



@end

@implementation ZOEAlertView
@synthesize lineSpacing             = _lineSpacing;
@synthesize titleFontSize           = _titleFontSize;
@synthesize messageFontSize         = _messageFontSize;
@synthesize buttonFontSize          = _buttonFontSize;
@synthesize titleTextColor          = _titleTextColor;
@synthesize messageTextColor        = _messageTextColor;
@synthesize buttonTextColor         = _buttonTextColor;

//初始化
- (instancetype)initWithTitle:(NSString*)title message:(NSString*)message  cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        //默认参数初始化
        self.backgroundColor    = [UIColor colorWithWhite:0 alpha:0.3];
        [self scale];
        _lineSpacing            = klineSpacing;
        _titleFontSize          = ktitleFontSize;
        _messageFontSize        = kmessageFontSize;
        _buttonFontSize         = kbuttonFontSize;
        _titleTextColor         = ktitleTextColor;
        _messageTextColor       = kmessageTextColor;
        _buttonTextColor  = kbuttonTextColor;
        _messageTextAlignment   = NSTextAlignmentCenter;
        _cancelButtonIndex = 0;
        _title = title;
        _message = message;
        _cancelButtonTitle = cancelButtonTitle;
        
        //将alertView存储在静态数组中
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            alertViewArray = [[NSMutableArray alloc]init];
        });
        
        //将alertView单独放在alertWindow中，确保alertView的父容器（window）不受外界干扰。
        static dispatch_once_t onceToken2;
        dispatch_once(&onceToken2, ^{
            alertWindow = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
            alertWindow.windowLevel = UIWindowLevelAlert;
            alertWindow.backgroundColor = [UIColor clearColor];
            [alertWindow makeKeyAndVisible];
            //获取系统delegate创建的window，将delegate window 转变回keyWindow，这样确保在外部调用keyWindow时都是系统创建的那个window。
            UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
            [window makeKeyAndVisible];
        });
        
        
        //添加子控件
        [self addSubview:self.alertContentView];
        //添加titleLabel
        if (_title&&_title.length>0) {
            [_alertContentView addSubview:self.titleLabel];
            _titleLabel.text = _title;
        }
        //添加消息详细Label
        if (_message&&_message.length>0) {
            self.messageContentView.messageLabel.font = [UIFont systemFontOfSize:_messageFontSize];
            self.messageContentView.messageLabel.textColor = _messageTextColor;
            self.messageContentView.paragraphStyle.lineSpacing = _lineSpacing;
            [self.messageContentView attrStrWithMessage:_message];
            [self.messageContentView addSubview:self.messageContentView.messageLabel];
            [_alertContentView addSubview:self.messageContentView];
        }
        
        //取消按钮
        if (_cancelButtonTitle&&_cancelButtonTitle.length>0) {
            UIButton *cancelButton = [ZOEAlertView createButton];
            [cancelButton setTitle:_cancelButtonTitle forState:UIControlStateNormal];
            [cancelButton addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
            [cancelButton setTitleColor:_buttonTextColor forState:UIControlStateNormal];
            [cancelButton.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
            [self.otherButtonTitles addObject:cancelButton];
        }
        //添加other按钮
        if (otherButtonTitles) {
            UIButton *btn = [ZOEAlertView createButton];
            [btn setTitle:otherButtonTitles forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
            [btn setTitleColor:_buttonTextColor forState:UIControlStateNormal];
            [btn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
            [self.otherButtonTitles addObject:btn];
            
            va_list argList;  //定义一个 argList 指针来访问参数表
            va_start(argList, otherButtonTitles);  //初始化 argList，让它指向第一个变参，otherButtonTitles 这里是第一个参数，虽然加了s,它不是数组。
            id arg;
            while ((arg = va_arg(argList, id))) //调用 argList 依次取出 参数，它会自带指向下一个参数
            {
                UIButton *btn1 = [ZOEAlertView createButton];
                [btn1 setTitle:arg forState:UIControlStateNormal];
                [btn1 setTitleColor:_buttonTextColor forState:UIControlStateNormal];
                [btn1.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
                [btn1 addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
                [self.otherButtonTitles addObject:btn1];
            }
            va_end(argList); // 收尾，记得关闭关闭 va_list
        }
        [self.alertContentView addSubview:self.operationalView];
        //设置按钮索引、绘制分割线
        int buttonIndex = (_cancelButtonTitle&&_cancelButtonTitle.length>0)?0:1;
        if (_otherButtonTitles.count==2) {
            for (int i=0; i<self.otherButtonTitles.count; i++) {
                UIButton *btn = _otherButtonTitles[i];
                btn.tag = kBtnTagAppend+buttonIndex++;
                [self.operationalView addSubview:btn];
            }
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0,0,kalertViewW,0.5)];
            line.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
            [self.operationalView addSubview:line];
            UIView *line1 = [[UIView alloc]initWithFrame:CGRectMake(kalertViewW/2.0,0,0.5,kBtnH)];
            line1.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
            [self.operationalView addSubview:line1];
            
        }else {
            for (int i=0; i<self.otherButtonTitles.count; i++) {
                UIButton *btn = _otherButtonTitles[i];
                btn.tag = kBtnTagAppend+buttonIndex++;
                [self.operationalView addSubview:btn];
                UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0,0+i*kBtnH,kalertViewW,0.5)];
                line.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
                [self.operationalView addSubview:line];
            }
        }
        //配置frame
        [self configFrame];
    }
    
    return self;
}

//展示控件
- (void)showWithBlock:(void (^)(NSInteger))Block {
    _MyBlock = Block;
    if (self.otherButtonTitles.count) {
        UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
        [window endEditing:YES];
        //如果alertView重复调用show方法，先将数组中原来的对象删除，然后继续添加到数组的最后面，
        for (ZOEAlertView *alertVeiw in alertViewArray) {
            if (alertVeiw == self) {
                alertVeiw.hidden = NO;
                [alertViewArray removeObject:alertVeiw];
                break;
            }
        }
        [alertViewArray addObject:self];
        [alertWindow addSubview:self];
        alertWindow.hidden = NO;
        //有新的alertView被展现，所以要将前一个alertView暂时隐藏
        if (alertViewArray.count-1>0) {
            ZOEAlertView *alertView = alertViewArray[alertViewArray.count-2];
            alertView.hidden = YES;
        }
    }else {
        alertWindow.hidden = YES;
    }
}

//动态配置子控件的位置及大小
- (void)configFrame {
    //必须至少有一个操作按钮才能展现控件
    if (self.otherButtonTitles.count) {
        CGFloat allBtnH = _otherButtonTitles.count<3?kBtnH:kBtnH*_otherButtonTitles.count;
        CGFloat alertViewH = allBtnH+21*_scale;//底部按钮操作区域高度+21点的空白
        if (_titleLabel) {
            alertViewH += (21+_titleLabel.font.pointSize)*_scale;
            _titleLabel.frame = CGRectMake(15*_scale,21*_scale,kalertViewW-30*_scale,_titleLabel.font.pointSize*_scale);
        }
        if (_message&&_message.length>0) {
            CGFloat y = 28*_scale;
            alertViewH += 28*_scale;
            if (_titleLabel) {
                y = (21+_titleLabel.font.pointSize+28)*_scale;
            }
            self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,0);
            self.messageContentView.messageLabel.frame = self.messageContentView.bounds;
            [self.messageContentView attrStrWithMessage:_message];
            [self.messageContentView.messageLabel sizeToFit];
            
            //alertViewH大于屏幕高度-300，那么对这个判断做等法判断出相等时messageContentView的高度
            if (self.messageContentView.messageLabel.frame.size.height+alertViewH>self.frame.size.height-200*_scale) {
                self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,self.frame.size.height-200*_scale-alertViewH);
                self.messageContentView.messageLabel.frame = self.messageContentView.bounds;
            }else {
                self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,self.messageContentView.messageLabel.frame.size.height);
                self.messageContentView.messageLabel.frame = self.messageContentView.bounds;
            }
            //使用sizeToFit之后对齐方式失效，
            self.messageContentView.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            self.messageContentView.messageLabel.textAlignment = _messageTextAlignment;
            alertViewH += self.messageContentView.frame.size.height;
        }
        //按钮操作区位置设置
        self.operationalView.frame = CGRectMake(0,alertViewH-allBtnH,kalertViewW,allBtnH);
        if (_otherButtonTitles.count == 2) {
            UIButton *btn = _otherButtonTitles[0];
            UIButton *btn1 = _otherButtonTitles[1];
            btn.frame = CGRectMake(0,0,kalertViewW/2.0,kBtnH);
            btn1.frame = CGRectMake(kalertViewW/2.0,0,kalertViewW/2.0,kBtnH);
        }else {
            for (int i=0;i<_otherButtonTitles.count;i++) {
                UIButton *btn = _otherButtonTitles[i];
                btn.frame = CGRectMake(0,(_otherButtonTitles.count-1-i)*kBtnH,kalertViewW,kBtnH);
            }
        }
        _alertContentView.frame = CGRectMake(0,0,kalertViewW,alertViewH);
        self.alertContentView.center = self.center;
    }
}

//操作按钮点击事件
- (void)clickButton:(UIButton *)sender {
    if (_MyBlock) {
        _MyBlock(sender.tag-kBtnTagAppend);
    }
    [self removeFromSuperview];
}

//重写父类方法(移除当前ZOEAlertView的同时将上一个ZOEAlertView显示出来)
- (void)removeFromSuperview {
    [super removeFromSuperview];
    //有可能不是按照数组倒序的顺序移除，所以需要遍历数组
    for (ZOEAlertView *alertVeiw in alertViewArray) {
        if (alertVeiw == self) {
            [alertViewArray removeObject:alertVeiw];
            break;
        }
    }
    //将数组的最后一个alertView显示出来
    if (alertViewArray.count>0) {
        ZOEAlertView *alertView = alertViewArray[alertViewArray.count-1];
        alertView.hidden = NO;
    }
    
    //当数组中没有alertView时将父容器隐藏。
    if (!alertViewArray.count) {
        alertWindow.hidden = YES;
    }
}

//移除当前的alertView（不会触发block回调）
- (void)dismissZOEAlertView {
    [self removeFromSuperview];
}

- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex {
    UIButton *btn = [self.operationalView viewWithTag:buttonIndex+kBtnTagAppend];
    if (btn) {
        [btn setTitleColor:color forState:UIControlStateNormal];
    }
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
        _alertContentView.layer.cornerRadius = 10*_scale;
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
        _titleLabel.textColor = _titleTextColor;
    }
    return _titleLabel;
}

- (MessageContentView *)messageContentView {
    if (!_messageContentView) {
        _messageContentView = [[MessageContentView alloc]init];
        _messageContentView.backgroundColor = [UIColor clearColor];
    }
    return _messageContentView;
}

- (UIView *)operationalView {
    if (!_operationalView) {
        _operationalView = [[UIView alloc]init];
        _operationalView.backgroundColor = [UIColor clearColor];
    }
    return _operationalView;
}

- (NSMutableArray *)otherButtonTitles {
    if (!_otherButtonTitles) {
        _otherButtonTitles = [[NSMutableArray alloc]init];
    }
    return _otherButtonTitles;
}

+ (UIButton *)createButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor clearColor];
    return btn;
}


//屏幕比例
- (CGFloat)scale {
    if (_scale == 0) {
        _scale = ([UIScreen mainScreen].bounds.size.height>480?[UIScreen mainScreen].bounds.size.height/667.0:0.851574);
    }
    return _scale;
}



#pragma mark - setter方法设置属性
//行高设置
- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
    self.messageContentView.paragraphStyle.lineSpacing = _lineSpacing*_scale;
    [self configFrame];
}

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    if (_titleLabel) {
        _titleFontSize = titleFontSize;
        _titleLabel.font = [UIFont systemFontOfSize:_titleFontSize*_scale];
        [self configFrame];
    }
}

- (void)setMessageFontSize:(CGFloat)messageFontSize {
    if (_message&&_message.length>0) {
        _messageFontSize = messageFontSize;
        self.messageContentView.messageLabel.font = [UIFont systemFontOfSize:_messageFontSize*_scale];
        [self configFrame];
    }
}

- (void)setButtonFontSize:(CGFloat)buttonFontSize {
    if (self.otherButtonTitles) {
         _buttonFontSize = buttonFontSize*_scale;
        for (UIButton *btn in _otherButtonTitles) {
            [btn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
        }
    }
}

- (void)setTitleTextColor:(UIColor *)titleTextColor {
    if (_titleLabel) {
        _titleTextColor = titleTextColor;
        _titleLabel.textColor = _titleTextColor;
    }
}

- (void)setMessageTextColor:(UIColor *)messageTextColor {
    if (_message&&_message.length>0) {
        _messageTextColor = messageTextColor;
        self.messageContentView.messageLabel.textColor = _messageTextColor;
    }
}

- (void)setButtonTextColor:(UIColor *)buttonTextColor {
    if (self.otherButtonTitles) {
        _buttonTextColor = buttonTextColor;
        for (UIButton *btn in _otherButtonTitles) {
            [btn setTitleColor:_buttonTextColor forState:UIControlStateNormal];
        }
    }
}

- (void)setMessageTextAlignment:(NSTextAlignment)messageTextAlignment {
    _messageTextAlignment = messageTextAlignment;
    [self configFrame];
}


@end
