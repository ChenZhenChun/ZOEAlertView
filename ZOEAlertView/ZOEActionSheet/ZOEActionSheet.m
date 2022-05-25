//
//  ZOEActionSheet.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/6/7.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "ZOEActionSheet.h"
#import "ZOECommonHead.h"

@interface ZOEActionSheet()

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
@property (nonatomic,assign) BOOL                       animated;//属性无用，只是为了容错。
@end

@implementation ZOEActionSheet
@synthesize buttonHeight = _buttonHeight;
@synthesize scale   = _scale;
//初始化
- (instancetype)initWithTitle:(NSString*)title  cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        //默认参数初始化
        [self scale];
        self.backgroundColor    = [UIColor colorWithWhite:0 alpha:0.7];
        _titleFontSize          = ktitleFontSize;
        _buttonFontSize         = kbuttonFontSize;
        _titleTextColor         = ktitleTextColor;
        _buttonTextColor        = kbuttonTextColor;
        _cancelButtonIndex      = 0;
        _title                  = title;
        _cancelButtonTitle      = cancelButtonTitle;
        _disAble                = YES;
        _zoeStyle               = ZOEAlertViewStyleActionSheet;
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
            _cancelButton.layer.cornerRadius = 5*_scale;
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
        [[ZOEWindow shareInstance] endEditing:YES];
        //如果actionSheet重复调用show方法，先将数组中原来的对象移除，然后继续添加到数组的最后面，
        for (UIView *actionSheet in [ZOEWindow shareStackArray]) {
            if (actionSheet == self) {
                actionSheet.hidden = NO;
                [[ZOEWindow shareStackArray] removeObject:actionSheet];
                break;
            }
        }
        [[ZOEWindow shareStackArray] addObject:self];
        [[ZOEWindow shareInstance].rootViewController.view addSubview:self];
        [ZOEWindow shareInstance].hidden = NO;
        //有新的actionSheet被展现，所以要将前一个actionSheet暂时隐藏
        if ([ZOEWindow shareStackArray].count-1>0) {
            UIView *alertView = [ZOEWindow shareStackArray][[ZOEWindow shareStackArray].count-2];
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
        [ZOEWindow shareInstance].hidden = YES;
    }
}

- (void)showWithBlock:(void(^)(NSInteger buttonIndex))block animated:(BOOL)animated {
    
}

//动态配置子控件的位置及大小
- (void)configFrame {
    //必须至少有一个操作按钮才能展现控件
    if (self.otherButtonTitles.count) {
        CGFloat allBtnH = self.buttonHeight*_otherButtonTitles.count;
        CGFloat actionSheeetViewH = allBtnH+(_cancelButton?20*_scale:10*_scale);
        
        //title区域frame设置
        if (_titleLabel) {
            actionSheeetViewH += 20*_scale+_titleLabel.font.pointSize;
            _titleLabel.frame = CGRectMake(0,10*_scale,self.bounds.size.width-30*_scale,_titleLabel.font.pointSize);
        }
        CGFloat contentViewH = actionSheeetViewH-(_cancelButton?(self.buttonHeight+20*_scale):10*_scale);
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
                                       _actionSheetContentView.frame.size.height-(10*_scale+self.buttonHeight),
                                       _actionSheetContentView.frame.size.width,
                                       self.buttonHeight);
            }else {
                btn.frame = CGRectMake(0,
                                       contentViewH-(btn.tag-kBtnTagAppend)*self.buttonHeight,
                                       _contentView.frame.size.width,
                                       self.buttonHeight);
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self configFrame];
    [self drawLine];
}

//绘制分割线
- (void)drawLine {
    for (UIView *view in [self.contentView subviews]) {
        if (view.tag == 74129)[view removeFromSuperview];
    }
    //设置按钮索引、绘制分割线
    CGFloat contentViewH = self.buttonHeight*(_cancelButton?(_otherButtonTitles.count-1):_otherButtonTitles.count)+(_titleLabel?20*_scale+_titleLabel.font.pointSize:0);
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
                                                               contentViewH-(btn.tag-kBtnTagAppend)*self.buttonHeight,
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
    //执行[[ZOEWindow shareStackArray] removeObject:actionSheet];_myBlock引用会消失（只出现在某个系统），所以这边做一下缓存。
    void(^myBlockTemp)(NSInteger buttonIndex) = _myBlock;
    for (UIView *actionSheet in [ZOEWindow shareStackArray]) {
        if (actionSheet == self) {
            [[ZOEWindow shareStackArray] removeObject:actionSheet];
            break;
        }
    }
    _myBlock = myBlockTemp;
    
    //将数组的最后一个alertView显示出来
    if ([ZOEWindow shareStackArray].count>0) {
        ZOEActionSheet *actionSheet = [ZOEWindow shareStackArray][[ZOEWindow shareStackArray].count-1];
        if ([ZOEActionSheet isKindOfClass:[actionSheet class]]) {
            [actionSheet showWithBlock:actionSheet.myBlock animated:actionSheet.animated];
        }else {
            [actionSheet showWithBlock:actionSheet.myBlock];
        }
    }
    
    //当数组中没有actionSheet时将父容器隐藏。
    if (![ZOEWindow shareStackArray].count) {
        [ZOEWindow shareInstance].hidden = YES;
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
    NSArray *data = [[ZOEWindow shareStackArray] filteredArrayUsingPredicate:predicate];
    for (ZOEActionSheet *actionSheet in data) {
        [actionSheet dismissZOEActionSheet];
    }
}

+ (NSArray *)getAllActionSheet {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@" zoeStyle = 1 "];
    NSArray *data = [[ZOEWindow shareStackArray] filteredArrayUsingPredicate:predicate];
    return data;
}

#pragma mark - Properties

//actionSheet内容父容器
- (UIView *)actionSheetContentView {
    if (!_actionSheetContentView) {
        _actionSheetContentView = [[UIView alloc]init];
        _actionSheetContentView.clipsToBounds = YES;
        _actionSheetContentView.layer.cornerRadius = 5*_scale;
        _actionSheetContentView.backgroundColor = [UIColor clearColor];
    }
    return _actionSheetContentView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc]init];
        _contentView.clipsToBounds = YES;
        _contentView.layer.cornerRadius = 5*_scale;
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
        if (_scale>1) return _scale = 1;
    }
    return _scale;
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    _isRedraw_showWithBlock = YES;
}

#pragma mark - setter方法设置属性

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    if (_titleLabel) {
        _titleFontSize = titleFontSize;
        _titleLabel.font = [UIFont systemFontOfSize:_titleFontSize];
        [self configFrame];
        [self drawLine];
    }
}

- (void)setButtonFontSize:(CGFloat)buttonFontSize {
    if (self.otherButtonTitles) {
        _buttonFontSize = buttonFontSize;
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

- (void)setButtonHeight:(CGFloat)buttonHeight {
    _buttonHeight = buttonHeight;
    _isRedraw_showWithBlock = YES;
}

- (CGFloat)buttonHeight {
    if (_buttonHeight) return _buttonHeight;
    _buttonHeight = kBtnH;
    return _buttonHeight;
}

@end
