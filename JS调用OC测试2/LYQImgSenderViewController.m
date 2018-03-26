//
//  ViewController.m
//  JS调用OC测试2
//
//  Created by leezb101 on 16/7/27.
//  Copyright © 2016年 leezb101. All rights reserved.
//

#import "TGAlbum.h"
#import "TGCameraNavigationController.h"
#import "LYQImgSenderViewController.h"
#import "ZYQAssetPickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "GTMBase64.h"

@interface LYQImgSenderViewController () <UIWebViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ZYQAssetPickerControllerDelegate, UIActionSheetDelegate, TGCameraDelegate>

@property (nonatomic, strong) NSMutableArray<NSString*>* copiedPaths;
@end

@implementation LYQImgSenderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"photoTest" ofType:@"html"];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL fileURLWithPath:path]];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    self.jsContext = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"aiImgSender"] = self;
    self.jsContext.exceptionHandler = ^(JSContext* context, JSValue* exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息捕获：%@", exceptionValue);
    };
}
#pragma mark - 测试3，自定义传图
/**
 *  JS端调用本地方法拉起ActionSheet
 */
- (void)pickerCall
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"请选择一个图片来源" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"相机拍照" otherButtonTitles:@"相册相片", nil];
    [actionSheet showInView:self.view];
}
/**
 *  选择图片来源
 *
 *  @param actionSheet ActionSheet
 *  @param buttonIndex 按钮序号
 */
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        TGCameraNavigationController* navigationController = [TGCameraNavigationController newWithCameraDelegate:self];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else if (buttonIndex == 1) {
        [self pickLocalPhotos];
    }
}

#pragma mark - 拍照
/**
 *  相机回调
 *
 *  @param image 相机拍摄的照片
 */
- (void)cameraDidTakePhoto:(UIImage*)image
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:dd"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
        NSDate* date = [NSDate date];
        NSString* timeSP = [formatter stringFromDate:date];
        NSString* filePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"camera_image_%@", timeSP]];
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:UIImageJPEGRepresentation(image, 0.5) attributes:nil];
        [self.copiedPaths addObject:filePath];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:^{
                JSValue* callBack3 = self.jsContext[@"pickerFinished"];
                [callBack3 callWithArguments:@[ filePath ]];
            }];
        });
    });
}

- (void)cameraDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 本地多选照片
/**
 *  本地图库选择照片
 */
- (void)pickLocalPhotos
{
    ZYQAssetPickerController* picker = [[ZYQAssetPickerController alloc] init];

    picker.maximumNumberOfSelection = 6;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.showEmptyGroups = NO;
    picker.delegate = self;
    picker.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id _Nonnull evaluatedObject, NSDictionary<NSString*, id>* _Nullable bindings) {
        if ([[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
            return NO;
        }
        else {
            return YES;
        }
    }];

    [self presentViewController:picker animated:YES completion:nil];
}
/**
 *  选择照片的处理
 *
 *  @param picker picker
 *  @param assets 选择的照片
 */
- (void)assetPickerController:(ZYQAssetPickerController*)picker didFinishPickingAssets:(NSArray*)assets
{
    __block NSString* filePath;
    NSMutableArray<NSString *>* pathsArr = [NSMutableArray array];
    NSMutableArray<NSString *>* base_Imgs = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* imgArray = [NSMutableArray array];
        int imgCount = (int)assets.count;
        for (int i = 0; i < imgCount; i++) {
            ALAssetRepresentation* assetRep = [assets[i] defaultRepresentation];
            CGImageRef cgRef = [assetRep fullScreenImage];
            UIImage* image = [UIImage imageWithCGImage:cgRef scale:assetRep.scale orientation:(UIImageOrientation)ALAssetOrientationUp];

            NSData *ddd = UIImageJPEGRepresentation(image, 0.5);
            NSString *base64_img = [GTMBase64 stringByEncodingData:ddd];


            //获取cache文件夹路径
            NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
            //增加时间戳
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
            [formatter setTimeZone:timeZone];
            NSDate* date = [NSDate date];
            NSString* timeSp = [formatter stringFromDate:date];

            filePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"image_%@_%d", timeSp, i]];

            [[NSFileManager defaultManager] createFileAtPath:filePath contents:UIImageJPEGRepresentation(image, 0.5) attributes:nil];
            [pathsArr addObject:filePath];

            [base_Imgs addObject:base64_img];
            NSLog(@"%@, index--->%d", filePath, i);
            [self.copiedPaths addObject:filePath];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [picker dismissViewControllerAnimated:YES completion:^{
                JSValue* callBack3 = self.jsContext[@"pickerFinished"];
                NSMutableArray* callBackArgus = [NSMutableArray array];
//                for (id path in pathsArr) {
//                    [callBackArgus addObject:path];
//                }
                for (id img in base_Imgs) {
                    [callBackArgus addObject:img];
                }
                NSLog(@"%@", callBackArgus);
                [callBack3 callWithArguments:callBackArgus];
            }];
        });
    });
}

#pragma mark - 完成发送回调
/**
 *  接收JS的回调，可做缓存图片删除操作
 *
 *  @param sendC JS传回来的状态字符串
 */
- (void)getEcho:(NSString*)sendC
{
    NSLog(@"get Echo====>%@", sendC);
    for (id path in self.copiedPaths) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        NSLog(@"是否存在文件===>%d", [[NSFileManager defaultManager] fileExistsAtPath:path]);
    }
    [self.copiedPaths removeAllObjects];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIWebView*)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.delegate = self;
    }
    return _webView;
}

- (NSMutableArray<NSString*>*)copiedPaths
{
    if (!_copiedPaths) {
        _copiedPaths = [NSMutableArray array];
    }
    return _copiedPaths;
}
@end
