//
//  ViewController.h
//  JS调用OC测试2
//
//  Created by leezb101 on 16/7/27.
//  Copyright © 2016年 leezb101. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

@protocol JSObjcDelegate <JSExport>
/**
 *  JS端调用的本地方法拉起图片来源选择
 */
- (void)pickerCall;
/**
 *  JS端的回调，通知本地完成上传，可在方法里进行删除缓存操作
 *
 *  @param sendC JS返回的状态字符串
 */
- (void)getEcho:(NSString*)sendC;

@end

@interface LYQImgSenderViewController : UIViewController <JSObjcDelegate>
@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) JSContext* jsContext;
@end
