//
//  VoiceConversionHelper.h
//  DemoiflyMSC
//
//  Created by zhangshaoyu on 16/4/28.
//  Copyright © 2016年 zhangshaoyu. All rights reserved.
//

#import <Foundation/Foundation.h>

// 导入头文件
#import "iflyMSC.framework/Headers/IFlyMSC.h"
#import "iflyMSC.framework/Headers/IFlySpeechUtility.h"
#import "iflyMSC/IFlySpeechConstant.h"

#pragma mark - 初始化参数类

/**************************************************************************/

@interface IATConfig : NSObject

+ (IATConfig *)sharedInstance;

+ (NSString *)mandarin;
+ (NSString *)cantonese;
+ (NSString *)henanese;
+ (NSString *)chinese;
+ (NSString *)english;
+ (NSString *)lowSampleRate;
+ (NSString *)highSampleRate;
+ (NSString *)isDot;
+ (NSString *)noDot;


/**
 以下参数，需要通过 iFlySpeechRecgonizer 进行设置
 */
@property (nonatomic, strong) NSString *speechTimeout;
@property (nonatomic, strong) NSString *vadEos;
@property (nonatomic, strong) NSString *vadBos;

@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSString *accent;

@property (nonatomic, strong) NSString *dot;
@property (nonatomic, strong) NSString *sampleRate;


/**
 以下参数无需设置 不必关
 */
@property (nonatomic, assign) BOOL haveView;
@property (nonatomic, strong) NSArray *accentIdentifer;
@property (nonatomic, strong) NSArray *accentNickName;

@end

/**************************************************************************/


#pragma mark - 语音听写类

@interface VoiceConversion : NSObject

/// 启动初始化语音程序
+ (void)VoiceInitialize;


/// 开始录音
- (void)voiceStart:(void (^)(BOOL isStart))startListening speechBegin:(void (^)(void))begin speechEnd:(void (^)(void))end speechError:(void (^)(BOOL isSuccess))error speechResult:(void (^)(NSString *text))result speechVolume:(void (^)(int volume))volume;

/// 取消录音
- (void)voiceCancel;

/// 停止录音
- (void)voiceStop;

@end

/*

 http://blog.csdn.net/potato512/article/details/51276208
 
 1、注册科大讯飞开发者帐号（http://www.xfyun.cn）
 2、下载开发平台（iOS、或Android，或其他）所需要的SDK（SDK包含：说明文档、SDK即iflyMSC.framework、Demo）
 3、项目中添加SDK（添加时，先将SDK复制粘贴到项目文件，再通过addframe的方法添加到项目引用），及相关联的framework
 添加方法：TARGETS-Build Phases-Link Binary With Libraries-"+"-Choose frameworks and libraries to add-add other，或选择对应的framework-add
 4、使用时要添加对应的头文件
 
 特别说明：
 1、使用SDK关联的APPID存在于下载的Demo中，如果SDK有替换的话APPID应该跟着一起替换。
 2、添加其他framework：
 libz.tbd
 libc++.tbd
 CoreGraphics.framework
 QuartzCore.framework
 AddressBook.framework
 CoreLocation.framework
 UIKit.framework
 AudioToolbox.framework
 Foundation.framework
 SystemConfiguration.framework
 AVFoundation.framework
 CoreTelephoney.framework
 3、Bitcode属性设置为NO（TARGETS-Build Settings-Build Options-Enable Bitcode-NO）
 4、在使用前，务必在AppDelegate的方法中"
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {}"进行初始化操作。
 5、需要有网络的情况下才能使用。
 
 
 
 */







