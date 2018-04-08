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
    if ([message containsString:@"<html"]&&[message containsString:@"</html"]) {
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
        _textField.backgroundColor = [UIColor clearColor];
    }
    return _textField;
}

@end
