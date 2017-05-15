//
//  ZOEAlertView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEAlertView.h"

typedef NS_ENUM(NSInteger, ZOEStyle) {
    ZOEAlertViewStyleAlert = 0,
    ZOEAlertViewStyleActionSheet
} ;

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

static dispatch_once_t                                  onceToken;
static dispatch_once_t                                  onceToken2;
static NSMutableArray                                   *alertViewArray;
static UIWindow                                         *alertWindow;


@interface ZOEAlertView()<UITextFieldDelegate,UITextViewDelegate>
@property (nonatomic)        CGFloat                    scale;
@property (nonatomic,strong) UIView                     *alertContentView;
@property (nonatomic,strong) UILabel                    *titleLabel;
@property (nonatomic,strong) MessageContentView         *messageContentView;
@property (nonatomic,strong) UIView                     *operationalView;

@property (nonatomic,copy)   NSString                   *title;
@property (nonatomic,copy)   NSString                   *message;
@property (nonatomic,copy)   NSString                   *cancelButtonTitle;
@property (nonatomic,strong) NSMutableArray             *otherButtonTitles;
@property (nonatomic,assign) BOOL                       animated;
@property (nonatomic,assign) NSInteger                  clickButtonIndex;
@property (nonatomic,assign) BOOL                       isVisible;//控件可见性
@property (nonatomic)        CGPoint                    oldCenterPoint;
@property (nonatomic,assign) ZOEStyle                   zoeStyle;
@property (nonatomic,copy) void(^myBlock)(NSInteger buttonIndex);
@property (nonatomic,copy) BOOL(^shouldDisBlock)(NSInteger buttonIndex);
@property (nonatomic,copy) void(^didDisBlock)(NSInteger buttonIndex);
@property (nonatomic,assign) BOOL                       isRedraw_showWithBlock;//调用showWithBlock 方法时是否需要重绘，默认不需要重绘。
@property (nonatomic,strong) UILabel                    *tipLabel;//提示性信息
@end

@implementation ZOEAlertView
//初始化
- (instancetype)initWithTitle:(NSString*)title message:(NSString*)message  cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        //默认参数初始化
        [self scale];
        self.backgroundColor    = [UIColor colorWithWhite:0 alpha:0.3];
        _lineSpacing            = klineSpacing;
        _titleFontSize          = ktitleFontSize;
        _messageFontSize        = kmessageFontSize;
        _buttonFontSize         = kbuttonFontSize;
        _titleTextColor         = ktitleTextColor;
        _messageTextColor       = kmessageTextColor;
        _buttonTextColor        = kbuttonTextColor;
        _messageTextAlignment   = NSTextAlignmentCenter;
        _cancelButtonIndex      = 0;
        _title                  = title;
        _message                = message;
        _cancelButtonTitle      = cancelButtonTitle;
        _textFieldPlaceholder   = @"";
        _disAble                = YES;
        _zoeStyle               = ZOEAlertViewStyleAlert;
        
        //将alertView存储在静态数组中
        dispatch_once(&onceToken, ^{
            alertViewArray = [[NSMutableArray alloc]init];
        });
        
        //将alertView单独放在alertWindow中，确保alertView的父容器（window）不受外界干扰。
        dispatch_once(&onceToken2, ^{
            alertWindow                 = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
            alertWindow.windowLevel     = UIWindowLevelAlert;
            alertWindow.backgroundColor = [UIColor clearColor];
            //获取系统delegate创建的window，将delegate window 转变回keyWindow，这样确保在外部调用keyWindow时都是系统创建的那个window。
            UIWindow *window            = [[[UIApplication sharedApplication]delegate]window];
            [alertWindow makeKeyAndVisible];
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
            self.messageContentView.messageLabel.font           = [UIFont systemFontOfSize:_messageFontSize];
            self.messageContentView.messageLabel.textColor      = _messageTextColor;
            self.messageContentView.paragraphStyle.lineSpacing  = _lineSpacing;
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
            [self addButtonWithTitle:otherButtonTitles];
            va_list argList;  //定义一个 argList 指针来访问参数表
            va_start(argList, otherButtonTitles);  //初始化 argList，让它指向第一个变参，otherButtonTitles 这里是第一个参数，虽然加了s,它不是数组。
            id arg;
            while ((arg = va_arg(argList, id))) //调用 argList 依次取出 参数，它会自带指向下一个参数
            {
                [self addButtonWithTitle:arg];
            }
            va_end(argList); // 收尾，记得关闭关闭 va_list
        }
        [self.alertContentView addSubview:self.operationalView];
        _isRedraw_showWithBlock = NO;
        [self drawLine];
        //配置frame
        [self configFrame];
    }
    
    return self;
}

- (void)setDelegate:(id<ZOEAlertViewDelegate>)delegate {
    _delegate = delegate;
    if ([self.delegate respondsToSelector:@selector(messageContentViewWithZOEAlertView:)]) {
        if (_messageContentView) {
            [_messageContentView removeFromSuperview];
            _messageContentView = nil;
        }
        _messageContentView = [self.delegate messageContentViewWithZOEAlertView:self];
        [self configFrame];
        [_alertContentView addSubview:self.messageContentView];
    }
}

//展示控件
- (void)showWithBlock:(void (^)(NSInteger))block {
    _myBlock = block;
    _animated = NO;
    if (self.otherButtonTitles.count) {
        if (_isRedraw_showWithBlock) {
            _isRedraw_showWithBlock = NO;
            [self drawLine];
            [self configFrame];
        }
        if (!_isVisible) {
            UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
            [window endEditing:YES];
        }
        if (_alertViewStyle == ZOEAlertViewStyleDefault) {
            if (!_isVisible)[alertWindow endEditing:NO];
        }else {
            [self.messageContentView.textField becomeFirstResponder];
        }
        _isVisible = YES;
        //如果alertView重复调用show方法，先将数组中原来的对象移除，然后继续添加到数组的最后面，
        for (UIView *alertVeiw in alertViewArray) {
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
            UIView *alertView = alertViewArray[alertViewArray.count-2];
            alertView.hidden = YES;
        }
        
        //设置延迟解决UILabel渲染缓慢的问题。
        self.alertContentView.alpha = 0;
        [UIView animateWithDuration:0 delay:0.00001 options:UIViewAnimationOptionTransitionNone animations:^{
            self.alertContentView.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }else {
        alertWindow.hidden = YES;
    }
}

- (void)showWithBlock:(void(^)(NSInteger buttonIndex))block animated:(BOOL)animated {
    [self showWithBlock:block];
    _animated = animated;
    if (_animated) {
        if (self.otherButtonTitles.count) {
            __block CGPoint center = self.alertContentView.center;
            center.y -= 100;
            self.alertContentView.center = center;
            /**
             usingSpringWithDamping 弹动比率 0~1，数值越小，弹动效果越明显
             initialSpringVelocity 则表示初始的速度，数值越大一开始移动越快,值得注意的是，初始速度取值较高而时间较短时，也会出现反弹情况
             **/
            [UIView animateWithDuration:1 delay:0.00001 usingSpringWithDamping:0.3 initialSpringVelocity:10 options:UIViewAnimationOptionTransitionNone animations:^{
                center.y += 100;
                self.alertContentView.center = center;
            } completion:^(BOOL finished) {
            }];
        }
    }
}

//动态配置子控件的位置及大小
- (void)configFrame {
    //必须至少有一个操作按钮才能展现控件
    if (self.otherButtonTitles.count) {
        CGFloat allBtnH = _otherButtonTitles.count<3?kBtnH:kBtnH*_otherButtonTitles.count;
        CGFloat alertViewH = allBtnH+21*_scale;//底部按钮操作区域高度+21点的空白
        
        //title区域frame设置
        if (_titleLabel) {
            alertViewH += 21*_scale+_titleLabel.font.pointSize;
            _titleLabel.frame = CGRectMake(15*_scale,21*_scale,kalertViewW-30*_scale,_titleLabel.font.pointSize);
        }
        
        //message区域frame设置
        if ([self.delegate respondsToSelector:@selector(heightForMessageContentView)]) {
            //代理对象自定的messageContentView模板frame设置
            CGFloat y = 28*_scale;
            alertViewH += 28*_scale;
            if (_titleLabel) {
                y = (21+28)*_scale+_titleLabel.font.pointSize;
            }
            CGFloat msgContentViewheight = [self.delegate heightForMessageContentView];
            self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,msgContentViewheight);
            alertViewH += msgContentViewheight;
        }else {
            //默认messageContentView模板frame设置
            if (_message&&_message.length>0) {
                CGFloat y = 28*_scale;
                alertViewH += 28*_scale;
                if (_titleLabel) {
                    y = (21+28)*_scale+_titleLabel.font.pointSize;
                }
                self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,0);
                self.messageContentView.messageLabel.frame = self.messageContentView.bounds;
                [self.messageContentView attrStrWithMessage:_message];
                [self.messageContentView.messageLabel sizeToFit];
                CGFloat textFieldH = 0;
                if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
                    textFieldH =44*_scale;
                }
                //alertViewH大于屏幕高度-300，那么对这个判断做等法判断出相等时messageContentView的高度
                if (self.messageContentView.messageLabel.frame.size.height+alertViewH+textFieldH>self.frame.size.height-200*_scale) {
                    self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,self.frame.size.height-200*_scale-alertViewH);
                    if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
                        self.messageContentView.messageLabel.frame =CGRectMake(0,0,kalertViewW-56*_scale,self.frame.size.height-200*_scale-alertViewH-textFieldH);
                        [self textFieldConfigByAlertViewStyleWithY:CGRectGetMaxY(self.messageContentView.messageLabel.frame)];
                    }else {
                        self.messageContentView.messageLabel.frame =CGRectMake(0,0,kalertViewW-56*_scale,self.frame.size.height-200*_scale-alertViewH);
                    }
                }else {
                    self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,self.messageContentView.messageLabel.frame.size.height+textFieldH);
                    if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
                        self.messageContentView.messageLabel.frame =CGRectMake(0,0,kalertViewW-56*_scale,self.messageContentView.frame.size.height-textFieldH);
                        [self textFieldConfigByAlertViewStyleWithY:CGRectGetMaxY(self.messageContentView.messageLabel.frame)];
                    }else {
                        self.messageContentView.messageLabel.frame =CGRectMake(0,0,kalertViewW-56*_scale,self.messageContentView.messageLabel.frame.size.height);
                    }
                }
                //使用sizeToFit之后对齐方式失效，
                self.messageContentView.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                self.messageContentView.messageLabel.textAlignment = _messageTextAlignment;
                alertViewH += self.messageContentView.frame.size.height;
            }else {
                if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
                    CGFloat y = 28*_scale;
                    alertViewH += 28*_scale;
                    if (_titleLabel) {
                        y = (21+28)*_scale+_titleLabel.font.pointSize;
                    }
                    self.messageContentView.frame = CGRectMake(28*_scale,y,kalertViewW-56*_scale,34*_scale);
                    [self textFieldConfigByAlertViewStyleWithY:-10*_scale];
                    self.messageContentView.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.messageContentView.messageLabel.textAlignment = _messageTextAlignment;
                    alertViewH += self.messageContentView.frame.size.height;
                }
            }
        }
        
        
        //按钮操作区frame设置
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

- (void)textFieldConfigByAlertViewStyleWithY:(CGFloat)y {
    if (self.alertViewStyle == ZOEAlertViewStylePlainTextInput) {
        self.messageContentView.textField.secureTextEntry = NO;
        self.messageContentView.textField.placeholder = _textFieldPlaceholder;
        self.messageContentView.textField.font = [UIFont systemFontOfSize:_messageFontSize];
        self.messageContentView.textField.frame = CGRectMake(0,y+10*_scale,kalertViewW-56*_scale,34*_scale);
    }else if (self.alertViewStyle == ZOEAlertViewStyleSecureTextInput) {
        self.messageContentView.textField.secureTextEntry = YES;
        self.messageContentView.textField.placeholder = _textFieldPlaceholder;
        self.messageContentView.textField.font = [UIFont systemFontOfSize:_messageFontSize];
        self.messageContentView.textField.frame = CGRectMake(0,y+10*_scale,kalertViewW-56*_scale,34*_scale);
    }
}

//设置button索引及绘制分割线
- (void)drawLine {
    for (UIView *view in [self.operationalView subviews]) {
        if (view.tag == 74129)[view removeFromSuperview];
    }
    int buttonIndex = (_cancelButtonTitle&&_cancelButtonTitle.length>0)?0:1;
    if (_otherButtonTitles.count==2) {
        for (int i=0; i<self.otherButtonTitles.count; i++) {
            UIButton *btn = _otherButtonTitles[i];
            btn.tag = kBtnTagAppend+buttonIndex++;
            [self.operationalView addSubview:btn];
        }
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0,0,kalertViewW,0.5)];
        line.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
        line.tag = 74129;
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
            line.tag = 74129;
            [self.operationalView addSubview:line];
        }
    }
}

//操作按钮点击事件
- (void)clickButton:(UIButton *)sender {
    _clickButtonIndex = sender.tag-kBtnTagAppend;
    [self removeFromSuperview];
    if (_myBlock&&!_isVisible) {
        _myBlock(_clickButtonIndex);
    }
}

//重写父类方法(移除当前ZOEAlertView的同时将上一个ZOEAlertView显示出来)
- (void)removeFromSuperview {
    if ((_shouldDisBlock&&!_shouldDisBlock(_clickButtonIndex))) {
        _isVisible = YES;
        [self showWithBlock:self.myBlock];
        NSLog(@"Instance method 'shouldDismissWithBlock:' return NO" );
        return;
    }else {
        _isVisible = NO;
    }
    [super removeFromSuperview];
    if (_didDisBlock)_didDisBlock(_clickButtonIndex);
    
    //有可能不是按照数组倒序的顺序移除，所以需要遍历数组
    //执行[alertViewArray removeObject:alertVeiw];_myBlock引用会消失（只出现在某个系统），所以这边做一下缓存。
    void(^myBlockTemp)(NSInteger buttonIndex) = _myBlock;
    for (UIView *alertVeiw in alertViewArray) {
        if (alertVeiw == self) {
            [alertViewArray removeObject:alertVeiw];
            break;
        }
    }
    _myBlock = myBlockTemp;
    
    //将数组的最后一个alertView显示出来
    if (alertViewArray.count>0) {
        ZOEAlertView *alertView = alertViewArray[alertViewArray.count-1];
        if ([ZOEAlertView isKindOfClass:[alertView class]]) {
            [alertView showWithBlock:alertView.myBlock animated:alertView.animated];
        }else {
            [alertView showWithBlock:alertView.myBlock];
        }
    }
    
    //当数组中没有alertView时将父容器隐藏。
    if (!alertViewArray.count) {
        alertWindow.hidden = YES;
    }
    
}

//移除当前的alertView（不会触发block回调）
- (void)dismissZOEAlertView {
    _clickButtonIndex = -1;
    [self removeFromSuperview];
}

- (void)shouldDismissWithBlock:(BOOL(^)(NSInteger buttonIndex))shouldDisBlock {
    _shouldDisBlock = shouldDisBlock;
}

- (void)didDismissWithBlock:(void(^)(NSInteger buttonIndex))didDisBlock {
    _didDisBlock = didDisBlock;
}

- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex {
    UIButton *btn = [self.operationalView viewWithTag:buttonIndex+kBtnTagAppend];
    if (btn) {
        [btn setTitleColor:color forState:UIControlStateNormal];
    }
}

- (void)addButtonWithTitle:(NSString *)title {
    if (title == nil || title == NULL)return;
    UIButton *btn = [ZOEAlertView createButton];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitleColor:_buttonTextColor forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
    [self.otherButtonTitles addObject:btn];
    _isRedraw_showWithBlock = YES;
}

//移除所有ZOEAlertView（不会触发block回调）
+ (void)dismissAllZOEAlertView {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@" disAble=1 AND zoeStyle = 0 "];
    NSArray *data = [alertViewArray filteredArrayUsingPredicate:predicate];
    for (ZOEAlertView *alertView in data) {
        [alertView dismissZOEAlertView];
    }
}

//处理键盘遮挡输入框的问题
- (void)handleKeyboard:(UIView *)textFieldOrTextView {
    if ([textFieldOrTextView isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)textFieldOrTextView;
        textField.delegate = self;
    }else if ([textFieldOrTextView isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)textFieldOrTextView;
        textView.delegate = self;
    }
}

//展示提示性信息
- (void)showTipViewWithMessage:(NSString *)message {
    if (!message || !message.length) return;
    self.tipLabel.text  = message;
    [self.tipLabel sizeToFit];
    CGRect frame        = self.tipLabel.frame;
    frame.size.width    = frame.size.width +40;
    if (frame.size.width>([[UIScreen mainScreen] bounds].size.width-30)) {
        frame.size.width = [[UIScreen mainScreen] bounds].size.width-30;
    }
    frame.size.height   = frame.size.height+15;
    _tipLabel.layer.cornerRadius = frame.size.height/2.0;
    _tipLabel.frame     = frame;
    _tipLabel.center    = CGPointMake(self.frame.size.width/2.0, self.frame.size.height*0.8);
    self.tipLabel.alpha = 1;
    //键盘弹出需要时间，如果在键盘弹出之前就加载提示语，提示语会被键盘遮挡，所以这边做了一个延迟处理。
    [self performSelector:@selector(handleTipViewAnimate) withObject:nil afterDelay:0.01];
}

//处理提示语信息动画
- (void)handleTipViewAnimate {
    UIView *view = [self keyboardView];
    [view addSubview:self.tipLabel];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 delay:2 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
        weakSelf.tipLabel.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

//获取键盘view
- (UIView *)keyboardView {
    UIWindow* tempWindow;
    //Because we cant get access to the UIKeyboard throught the SDK we will just use UIView.
    //UIKeyboard is a subclass of UIView anyways
    UIView* keyboard;
    
    //Check each window in our application
    for(int c = 0; c < [[[UIApplication sharedApplication] windows] count]; c ++) {
        //Get a reference of the current window
        tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:c];
        
        //Get a reference of the current view
        for(int i = 0; i < [tempWindow.subviews count]; i++) {
            keyboard = [tempWindow.subviews objectAtIndex:i];
            if([[keyboard description] hasPrefix:@"(lessThen)UIKeyboard"] == YES) {
                //If we get to this point, then our UIView "keyboard" is referencing our keyboard.
                return keyboard;
            }
        }
        
        for(UIView* potentialKeyboard in tempWindow.subviews) {
            // if the real keyboard-view is found, remember it.
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                if([[potentialKeyboard description] hasPrefix:@"<UILayoutContainerView"] == YES)
                    keyboard = potentialKeyboard;
            }
            else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
                if([[potentialKeyboard description] hasPrefix:@"<UIPeripheralHost"] == YES)
                    keyboard = potentialKeyboard;
            }
            else {
                if([[potentialKeyboard description] hasPrefix:@"<UIKeyboard"] == YES)
                    keyboard = potentialKeyboard;
            }
        }
    }
    return keyboard;
}

#pragma mark - UITextFieldDelegate
//开始编辑输入框的时候，软键盘出现，执行此事件
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.oldCenterPoint = self.alertContentView.center;
    //获取textField在屏幕上的坐标
    CGPoint textFieldPoint = [[textField superview]convertPoint:textField.frame.origin toView:alertWindow];
    int offset = textFieldPoint.y + textField.frame.size.height - (alertWindow.frame.size.height-216.0)+90;//键盘高度216
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    if(offset > 0) {
        CGPoint centerPoint = self.alertContentView.center;
        centerPoint.y = centerPoint.y-offset;
        self.alertContentView.center = centerPoint;
    }
    [UIView commitAnimations];
}
//输入框编辑完成以后，将视图恢复到原始状态
-(void)textFieldDidEndEditing:(UITextField *)textField {
    self.alertContentView.center = self.oldCenterPoint;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [alertWindow endEditing:YES];
    return YES;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [alertWindow endEditing:YES];
}



#pragma mark -textViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.oldCenterPoint = self.alertContentView.center;
    //获取textField在屏幕上的坐标
    CGPoint textFieldPoint = [[textView superview]convertPoint:textView.frame.origin toView:alertWindow];
    int offset = textFieldPoint.y + textView.frame.size.height - (alertWindow.frame.size.height - 216.0)+90;//键盘高度216
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    if(offset > 0) {
        CGPoint centerPoint = self.alertContentView.center;
        centerPoint.y = centerPoint.y-offset;
        self.alertContentView.center = centerPoint;
    }
    [UIView commitAnimations];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.alertContentView.center = self.oldCenterPoint;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    /**
    判断输入的字是否是回车，即按下return
    返回NO，就代表return键值失效，即页面上按下return，不会出现换行，如果为yes，则输入页面会换行
     **/
    if ([text isEqualToString:@"\n"]){ //
        [alertWindow endEditing:YES];
        return NO;
    }
    
    return YES;
}

#pragma mark - Properties

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

- (UILabel *)tipLabel {
    if (_tipLabel)return _tipLabel;
    _tipLabel = [[UILabel alloc]init];
    _tipLabel.numberOfLines = 0;
    _tipLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    _tipLabel.textColor = [UIColor whiteColor];
    _tipLabel.bounds    = CGRectMake(0, 30,300,30);
    _tipLabel.center    = CGPointMake(self.alertContentView.frame.size.width/2.0, self.alertContentView.frame.size.height/2.0);
    _tipLabel.font      = [UIFont systemFontOfSize:15*_scale];
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.userInteractionEnabled = NO;
    _tipLabel.layer.cornerRadius = 15;
    _tipLabel.clipsToBounds = YES;
    return _tipLabel;
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

- (void)setAlertViewStyle:(ZOEAlertViewStyle)alertViewStyle {
    _alertViewStyle = alertViewStyle;
    if (_alertViewStyle != ZOEAlertViewStyleDefault) {
        self.messageContentView.textField.delegate = self;
        [self.alertContentView addSubview:self.messageContentView];
        [self.messageContentView addSubview:self.messageContentView.textField];
    }
    [self configFrame];
}

- (void)setTextFieldPlaceholder:(NSString *)textFieldPlaceholder {
    _textFieldPlaceholder = textFieldPlaceholder;
    if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
        self.messageContentView.textField.placeholder = _textFieldPlaceholder;
    }
}

- (UITextField *)textField {
    if (self.alertViewStyle != ZOEAlertViewStyleDefault) {
        return self.messageContentView.textField;
    }
    NSLog(@"ZOEAlertViewStyle is ZOEAlertViewStyleDefault, so the textField returns nil");
    return nil;
}

@end







@interface ZOEActionSheet()
@property (nonatomic)        CGFloat                    scale;
@property (nonatomic,strong) UIView                     *actionSheetContentView;
@property (nonatomic,strong) UIView                     *contentView;
@property (nonatomic,strong) UIButton                   *cancelButton;
@property (nonatomic,strong) UILabel                    *titleLabel;

@property (nonatomic,copy)   NSString                   *title;
@property (nonatomic,copy)   NSString                   *cancelButtonTitle;
@property (nonatomic,strong) NSMutableArray             *otherButtonTitles;
@property (nonatomic,assign) NSInteger                  clickButtonIndex;
@property (nonatomic,assign) ZOEStyle                   zoeStyle;
@property (nonatomic,copy) void(^myBlock)(NSInteger buttonIndex);
@property (nonatomic)        CGPoint                    oldCenterPoint;
@property (nonatomic,assign) BOOL                       isRedraw_showWithBlock;//调用showWithBlock 方法时是否需要重绘，默认不需要重绘。
@end

@implementation ZOEActionSheet
//初始化
- (instancetype)initWithTitle:(NSString*)title  cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        //默认参数初始化
        [self scale];
        self.backgroundColor    = [UIColor colorWithWhite:0 alpha:0.3];
        _titleFontSize          = ktitleFontSize;
        _buttonFontSize         = kbuttonFontSize;
        _titleTextColor         = ktitleTextColor;
        _buttonTextColor        = kbuttonTextColor;
        _cancelButtonIndex      = 0;
        _title                  = title;
        _cancelButtonTitle      = cancelButtonTitle;
        _disAble                = YES;
        _zoeStyle               = ZOEAlertViewStyleActionSheet;
        //将actionSheet存储在静态数组中
        dispatch_once(&onceToken, ^{
            alertViewArray = [[NSMutableArray alloc]init];
        });
        
        //将actionSheet单独放在alertWindow中，确保actionSheet的父容器（window）不受外界干扰。
        dispatch_once(&onceToken2, ^{
            alertWindow                 = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
            alertWindow.windowLevel     = UIWindowLevelAlert;
            alertWindow.backgroundColor = [UIColor clearColor];
            //获取系统delegate创建的window，将delegate window 转变回keyWindow，这样确保在外部调用keyWindow时都是系统创建的那个window。
            UIWindow *window            = [[[UIApplication sharedApplication]delegate]window];
            [alertWindow makeKeyAndVisible];
            [window makeKeyAndVisible];
        });
        
        //添加子控件
        [self addSubview:self.actionSheetContentView];
        [self.actionSheetContentView addSubview:self.contentView];
        //添加titleLabel
        if (_title&&_title.length>0) {
            [self.contentView addSubview:self.titleLabel];
            _titleLabel.text = _title;
        }
        
        //取消按钮
        if (_cancelButtonTitle&&_cancelButtonTitle.length>0) {
            _cancelButton = [ZOEActionSheet createButton];
            _cancelButton.backgroundColor = [UIColor whiteColor];
            _cancelButton.clipsToBounds = YES;
            _cancelButton.layer.cornerRadius = 10*_scale;
            [_cancelButton setTitle:_cancelButtonTitle forState:UIControlStateNormal];
            [_cancelButton addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
            [_cancelButton setTitleColor:_buttonTextColor forState:UIControlStateNormal];
            [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
            [self.otherButtonTitles addObject:_cancelButton];
        }
        //添加other按钮
        if (otherButtonTitles) {
            [self addButtonWithTitle:otherButtonTitles];
            va_list argList;  //定义一个 argList 指针来访问参数表
            va_start(argList, otherButtonTitles);  //初始化 argList，让它指向第一个变参，otherButtonTitles 这里是第一个参数，虽然加了s,它不是数组。
            id arg;
            while ((arg = va_arg(argList, id))) //调用 argList 依次取出 参数，它会自带指向下一个参数
            {
                [self addButtonWithTitle:arg];
            }
            va_end(argList); // 收尾，记得关闭关闭 va_list
        }
        _isRedraw_showWithBlock = NO;
        [self drawLine];
        //配置frame
        [self configFrame];
    }
    
    return self;
}

//展示控件
- (void)showWithBlock:(void (^)(NSInteger))block {
    _myBlock = block;
    if (self.otherButtonTitles.count) {
        if (_isRedraw_showWithBlock) {
            _isRedraw_showWithBlock = NO;
            [self drawLine];
            [self configFrame];
        }
        UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
        [window endEditing:YES];
        [alertWindow endEditing:YES];
        //如果actionSheet重复调用show方法，先将数组中原来的对象移除，然后继续添加到数组的最后面，
        for (UIView *actionSheet in alertViewArray) {
            if (actionSheet == self) {
                actionSheet.hidden = NO;
                [alertViewArray removeObject:actionSheet];
                break;
            }
        }
        [alertViewArray addObject:self];
        [alertWindow addSubview:self];
        alertWindow.hidden = NO;
        //有新的actionSheet被展现，所以要将前一个actionSheet暂时隐藏
        if (alertViewArray.count-1>0) {
            UIView *alertView = alertViewArray[alertViewArray.count-2];
            alertView.hidden = YES;
        }
        
        //设置延迟解决UILabel渲染缓慢的问题。
        __block CGPoint center = _oldCenterPoint;
        center.y += self.actionSheetContentView.frame.size.height;
        self.actionSheetContentView.center = center;
        [UIView animateWithDuration:0.2 delay:0.00001 options:UIViewAnimationOptionTransitionNone animations:^{
            self.actionSheetContentView.center = _oldCenterPoint;
        } completion:^(BOOL finished) {
        }];
    }else {
        alertWindow.hidden = YES;
    }
}

//动态配置子控件的位置及大小
- (void)configFrame {
    //必须至少有一个操作按钮才能展现控件
    if (self.otherButtonTitles.count) {
        CGFloat allBtnH = kBtnH*_otherButtonTitles.count;
        CGFloat actionSheeetViewH = allBtnH+(_cancelButton?20*_scale:10*_scale);
        
        //title区域frame设置
        if (_titleLabel) {
            actionSheeetViewH += 20*_scale+_titleLabel.font.pointSize;
            _titleLabel.frame = CGRectMake(0,10*_scale,self.bounds.size.width-30*_scale,_titleLabel.font.pointSize);
        }
        CGFloat contentViewH = actionSheeetViewH-(_cancelButton?(kBtnH+20*_scale):10*_scale);
        //按钮操作区frame设置
        self.actionSheetContentView.frame = CGRectMake(15*_scale,
                                                       self.bounds.size.height-actionSheeetViewH,
                                                       self.bounds.size.width-30*_scale,
                                                       actionSheeetViewH);
        _oldCenterPoint = self.actionSheetContentView.center;
        self.contentView.frame = CGRectMake(0,0,
                                            _actionSheetContentView.frame.size.width,
                                            contentViewH);
        for (int i=0;i<_otherButtonTitles.count;i++) {
            UIButton *btn = _otherButtonTitles[i];
            if (btn.tag == kBtnTagAppend) {
                btn.frame = CGRectMake(0,
                                       _actionSheetContentView.frame.size.height-(10*_scale+kBtnH),
                                       _actionSheetContentView.frame.size.width,
                                       kBtnH);
            }else {
                btn.frame = CGRectMake(0,
                                       contentViewH-(btn.tag-kBtnTagAppend)*kBtnH,
                                       _contentView.frame.size.width,
                                       kBtnH);
            }
        }
    }
}

//绘制分割线
- (void)drawLine {
    for (UIView *view in [self.contentView subviews]) {
        if (view.tag == 74129)[view removeFromSuperview];
    }
    //设置按钮索引、绘制分割线
    CGFloat contentViewH = kBtnH*(_cancelButton?(_otherButtonTitles.count-1):_otherButtonTitles.count)+(_titleLabel?20*_scale+_titleLabel.font.pointSize:0);
    int buttonIndex = (_cancelButtonTitle&&_cancelButtonTitle.length>0)?0:1;
    for (int i=0; i<self.otherButtonTitles.count; i++) {
        UIButton *btn = _otherButtonTitles[i];
        btn.tag = kBtnTagAppend+buttonIndex++;
        if (btn.tag == kBtnTagAppend) {
            [self.actionSheetContentView addSubview:_cancelButton];
            continue;
        }
        [self.contentView addSubview:btn];
        if (!_titleLabel && i == self.otherButtonTitles.count-1) {
            break;
        }
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0,
                                                               contentViewH-(btn.tag-kBtnTagAppend)*kBtnH,
                                                               self.bounds.size.width-30*_scale,
                                                               0.5)];
        line.backgroundColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1];
        line.tag = 74129;
        [self.contentView addSubview:line];
    }
}

//操作按钮点击事件
- (void)clickButton:(UIButton *)sender {
    _clickButtonIndex = sender.tag-kBtnTagAppend;
    __block CGPoint center = _oldCenterPoint;
    [UIView animateWithDuration:0.2 delay:0.00001 options:UIViewAnimationOptionTransitionNone animations:^{
        center.y += self.actionSheetContentView.frame.size.height;
        self.actionSheetContentView.center = center;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.actionSheetContentView.center = _oldCenterPoint;
        if (_myBlock) {
            _myBlock(_clickButtonIndex);
        }
    }];
}

//重写父类方法(移除当前actionSheet的同时将上一个actionSheet显示出来)
- (void)removeFromSuperview {
    [super removeFromSuperview];
    //有可能不是按照数组倒序的顺序移除，所以需要遍历数组
    //执行[alertViewArray removeObject:actionSheet];_myBlock引用会消失（只出现在某个系统），所以这边做一下缓存。
    void(^myBlockTemp)(NSInteger buttonIndex) = _myBlock;
    for (UIView *actionSheet in alertViewArray) {
        if (actionSheet == self) {
            [alertViewArray removeObject:actionSheet];
            break;
        }
    }
    _myBlock = myBlockTemp;
    
    //将数组的最后一个alertView显示出来
    if (alertViewArray.count>0) {
        ZOEAlertView *actionSheet = alertViewArray[alertViewArray.count-1];
        if ([ZOEAlertView isKindOfClass:[actionSheet class]]) {
            [actionSheet showWithBlock:actionSheet.myBlock animated:actionSheet.animated];
        }else {
            [actionSheet showWithBlock:actionSheet.myBlock];
        }
    }
    
    //当数组中没有actionSheet时将父容器隐藏。
    if (!alertViewArray.count) {
        alertWindow.hidden = YES;
    }
}

//移除当前的actionSheet（不会触发block回调）
- (void)dismissZOEActionSheet {
    _clickButtonIndex = -1;
    [self removeFromSuperview];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    __block CGPoint center = _oldCenterPoint;
    [UIView animateWithDuration:0.2 delay:0.00001 options:UIViewAnimationOptionTransitionNone animations:^{
        center.y += self.actionSheetContentView.frame.size.height;
        self.actionSheetContentView.center = center;
    } completion:^(BOOL finished) {
        [self dismissZOEActionSheet];
        self.actionSheetContentView.center = _oldCenterPoint;
    }];
}

- (void)setButtonTextColor:(UIColor *)color buttonIndex:(NSInteger)buttonIndex {
    UIButton *btn;
    if (buttonIndex == _cancelButtonIndex) {
        btn = [self.actionSheetContentView viewWithTag:buttonIndex+kBtnTagAppend];
    }else {
        btn = [_contentView viewWithTag:buttonIndex+kBtnTagAppend];
    }
    if (btn) {
        [btn setTitleColor:color forState:UIControlStateNormal];
    }
}

- (void)addButtonWithTitle:(NSString *)title {
    if (title == nil || title == NULL)return;
    UIButton *btn = [ZOEActionSheet createButton];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitleColor:_buttonTextColor forState:UIControlStateNormal];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:_buttonFontSize]];
    [self.otherButtonTitles addObject:btn];
    _isRedraw_showWithBlock = YES;
}

//移除所有ZOEActionSheet（不会触发block回调）
+ (void)dismissAllZOEActionSheet {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@" disAble=1  AND zoeStyle = 1 "];
    NSArray *data = [alertViewArray filteredArrayUsingPredicate:predicate];
    for (ZOEActionSheet *actionSheet in data) {
        [actionSheet dismissZOEActionSheet];
    }
}

#pragma mark - Properties

//actionSheet内容父容器
- (UIView *)actionSheetContentView {
    if (!_actionSheetContentView) {
        _actionSheetContentView = [[UIView alloc]init];
        _actionSheetContentView.clipsToBounds = YES;
        _actionSheetContentView.layer.cornerRadius = 10*_scale;
        _actionSheetContentView.backgroundColor = [UIColor clearColor];
    }
    return _actionSheetContentView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc]init];
        _contentView.clipsToBounds = YES;
        _contentView.layer.cornerRadius = 10*_scale;
        _contentView.backgroundColor = [UIColor whiteColor];
    }
    return _contentView;
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

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    if (_titleLabel) {
        _titleFontSize = titleFontSize;
        _titleLabel.font = [UIFont systemFontOfSize:_titleFontSize*_scale];
        [self configFrame];
        [self drawLine];
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

- (void)setButtonTextColor:(UIColor *)buttonTextColor {
    if (self.otherButtonTitles) {
        _buttonTextColor = buttonTextColor;
        for (UIButton *btn in _otherButtonTitles) {
            [btn setTitleColor:_buttonTextColor forState:UIControlStateNormal];
        }
    }
}

@end
