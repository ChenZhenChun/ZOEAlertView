//
//  MessageContentView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 2017/2/16.
//  Copyright © 2017年 zoenet. All rights reserved.
//

#import "MessageContentView.h"

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
    self.attrStr = [self.attrStr initWithString:message];
    //调整行间距
    [_attrStr addAttribute:NSParagraphStyleAttributeName value:self.paragraphStyle range:NSMakeRange(0,_attrStr.string.length)];
    _messageLabel.attributedText = _attrStr;
    return _attrStr;
}

- (NSMutableAttributedString *)attrStr {
    if (!_attrStr) {
        _attrStr = [[NSMutableAttributedString alloc]init];
    }
    return _attrStr;
}

@end
