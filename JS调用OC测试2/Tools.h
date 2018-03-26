//
//  Tools.h
//  JS调用OC测试2
//
//  Created by leezb101 on 16/7/27.
//  Copyright © 2016年 leezb101. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Tools : NSObject
+ (UILabel *)createLabel:(NSString *)content frame:(CGRect)frame color:(UIColor *)color font:(UIFont *)font aliment:(NSTextAlignment)aliment;

@end
