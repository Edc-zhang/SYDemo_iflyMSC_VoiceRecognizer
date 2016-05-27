//
//  ViewController.m
//  DemoiflyMSC
//
//  Created by zhangshaoyu on 16/4/28.
//  Copyright © 2016年 zhangshaoyu. All rights reserved.
//

#import "ViewController.h"
#import "VoiceConversion.h"

@interface ViewController ()

@property (nonatomic, strong) VoiceConversion *voiceConversion;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIBarButtonItem *startItem = [[UIBarButtonItem alloc] initWithTitle:@"start" style:UIBarButtonItemStyleDone target:self action:@selector(startItemClick:)];
    UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithTitle:@"stop" style:UIBarButtonItemStyleDone target:self action:@selector(stopItemClick:)];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelItemClick:)];
    self.navigationItem.rightBarButtonItems = @[startItem, stopItem, cancelItem];
    
    self.title = @"科大讯飞语音";
    
    [self setUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 视图

- (void)setUI
{
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, CGRectGetWidth(self.view.bounds) - 10.0 * 2, 40.0)];
    [self.view addSubview:self.messageLabel];
    self.messageLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - 响应

- (void)startItemClick:(UIBarButtonItem *)item
{
    ViewController __weak *weakSelf = self;
    [self.voiceConversion voiceStart:^(BOOL isStart) {
        
        NSLog(@"1 start");
        
        if (isStart)
        {
            weakSelf.messageLabel.text = @"开始录音";
        }
        else
        {
            weakSelf.messageLabel.text = @"启动识别服务失败，请稍后重试";
        }
    } speechBegin:^{
        NSLog(@"2 begin");
        weakSelf.messageLabel.text = @"正在录音...";
    } speechEnd:^{
        NSLog(@"3 end");
        weakSelf.messageLabel.text = @"正在识别...";
    } speechError:^(BOOL isSuccess) {
        NSLog(@"4 error");
    } speechResult:^(NSString *text) {
        NSLog(@"5 result");
        weakSelf.messageLabel.text = text;
    } speechVolume:^(int volume) {
        NSLog(@"6 volume");
        NSString *volumeString = [NSString stringWithFormat:@"音量：%d", volume];
        weakSelf.messageLabel.text = volumeString;
    }];
}

- (void)stopItemClick:(UIBarButtonItem *)item
{
    [self.voiceConversion voiceStop];
    
    self.messageLabel.text = @"停止录音";
}

- (void)cancelItemClick:(UIBarButtonItem *)item
{
    [self.voiceConversion voiceCancel];
    
    self.messageLabel.text = @"取消识别";
}

#pragma mark - getter

- (VoiceConversion *)voiceConversion
{
    if (!_voiceConversion)
    {
        _voiceConversion = [[VoiceConversion alloc] init];
    }
    
    return _voiceConversion;
}

@end
