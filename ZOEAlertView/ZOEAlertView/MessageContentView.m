//
//  MessageContentView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/16.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "MessageContentView.h"

@interface MessageContentView()
@property (nonatomic,strong) NSMutableAttributedString  *attrStr;
@end

@implementation MessageContentView

//消息详细
- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc]init];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.numberOfLines = 0;
    }
    return _messageLabel;
}

- (NSMutableParagraphStyle *)paragraphStyle {
    if (!_paragraphStyle) {
        _paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    }
    return _paragraphStyle;
}

- (NSMutableAttributedString *)attrStrWithMessage:(NSString *)message {
    if (([message containsString:@"<html"]&&[message containsString:@"</html"])
        ||([message containsString:@"<body"]&&[message containsString:@"</body"])
        ||([message containsString:@"<div"]&&[message containsString:@"</div"])
        ||([message containsString:@"<p"]&&[message containsString:@"</p"])) {
        self.attrStr = [self.attrStr initWithData:[message dataUsingEncoding:NSUnicodeStringEncoding]
                                          options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType}
                               documentAttributes:nil error:nil];
    }else {
        self.attrStr = [self.attrStr initWithString:message];
        
    }
    //调整行间距
    [_attrStr addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(0,_attrStr.string.length)];
    if (_messageLabel)_messageLabel.attributedText = _attrStr;
    return _attrStr;
}

- (NSMutableAttributedString *)attrStr {
    if (!_attrStr) {
        _attrStr = [[NSMutableAttributedString alloc]init];
    }
    return _attrStr;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc]init];
        _textField.layer.borderWidth = 0.5;
        _textField.layer.borderColor = [UIColor colorWithRed:207/255.0 green:210/255.0 blue:213/255.0 alpha:1].CGColor;
        _textField.textAlignment = NSTextAlignmentLeft;
        UIImageView *leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,15,34)];
        leftView.backgroundColor = [UIColor clearColor];
        _textField.leftView = leftView;
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.backgroundColor = [UIColor clearColor];
    }
    return _textField;
}

- (ZOEPlaceholderTextView *)textView {
    if (_textView) return _textView;
    _textView = [[ZOEPlaceholderTextView alloc] initWithFrame:CGRectMake(0,0,270,98)];
    _textView.charVerifyType = Length;
    _textView.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:1.0f];
    _textView.layer.cornerRadius = 5;
    _textView.layer.masksToBounds = YES;
    _textView.font = [UIFont systemFontOfSize:14];
    [_textView setValue:[UIFont systemFontOfSize:14] forKeyPath:@"placeHolderLabel.font"];
    return _textView;
}

@end
