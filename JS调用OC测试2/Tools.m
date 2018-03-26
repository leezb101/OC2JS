//
//  Tools.m
//  JS调用OC测试2
//
//  Created by leezb101 on 16/7/27.
//  Copyright © 2016年 leezb101. All rights reserved.
//

#import "Tools.h"

@implementation Tools

+ (UILabel *)createLabel:(NSString *)content frame:(CGRect)frame color:(UIColor *)color font:(UIFont *)font aliment:(NSTextAlignment)aliment
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.text = content;
    label.textColor = color;
    label.font = font;
    label.textAlignment = aliment;
    return label;
}

@end
