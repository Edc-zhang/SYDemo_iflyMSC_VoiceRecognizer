//
//  VoiceConversionHelper.m
//  DemoiflyMSC
//
//  Created by zhangshaoyu on 16/4/28.
//  Copyright © 2016年 zhangshaoyu. All rights reserved.
//

#import "VoiceConversion.h"

#pragma mark - 初始化参数类

/**************************************************************************/

static NSString *const PUTONGHUA = @"mandarin";
static NSString *const YUEYU     = @"cantonese";
static NSString *const HENANHUA  = @"henanese";
static NSString *const ENGLISH   = @"en_us";
static NSString *const CHINESE   = @"zh_cn";

@implementation IATConfig

- (id)init
{
    self  = [super init];
    if (self)
    {
        [self defaultSetting];
        return  self;
    }
    return nil;
}

+ (IATConfig *)sharedInstance
{
    static IATConfig  * instance = nil;
    static dispatch_once_t predict;
    dispatch_once(&predict, ^{
        instance = [[IATConfig alloc] init];
    });
    return instance;
}

- (void)defaultSetting
{
    _speechTimeout = @"30000";
    _vadEos = @"3000";
    _vadBos = @"3000";
    _dot = @"1";
    _sampleRate = @"16000";
    _language = CHINESE;
    _accent = PUTONGHUA;
    _haveView = NO;//默认是不dai界面的
    _accentNickName = [[NSArray alloc] initWithObjects:@"粤语", @"普通话", @"河南话", @"英文", nil];
}

+ (NSString *)mandarin
{
    return PUTONGHUA;
}

+ (NSString *)cantonese
{
    return YUEYU;
}

+ (NSString *)henanese
{
    return HENANHUA;
}

+ (NSString *)chinese
{
    return CHINESE;
}

+ (NSString *)english
{
    return ENGLISH;
}

+ (NSString *)lowSampleRate
{
    return @"8000";
}

+ (NSString *)highSampleRate
{
    return @"16000";
}

+ (NSString *)isDot
{
    return @"1";
}

+ (NSString *)noDot
{
    return @"0";
}

@end

/**************************************************************************/

#pragma mark - 语音听写类

static NSString *const VoiceAPPID   = @"572016e4";
static NSString *const VoiceTimeOut = @"20000";

@interface VoiceConversion () <IFlySpeechRecognizerDelegate>

@property (nonatomic, strong) NSMutableString *resultText;
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;

@property (nonatomic, copy) void (^beginSpeech)(void);
@property (nonatomic, copy) void (^endSpeech)(void);
@property (nonatomic, copy) void (^errorSpeech)(BOOL isSuccess);
@property (nonatomic, copy) void (^resultSpeech)(NSString *text);
@property (nonatomic, copy) void (^volumeSpeech)(int volume);

@property (nonatomic, strong) NSTimer *countDownTimer;
@property (nonatomic, assign) int countDownVolume;

@end

@implementation VoiceConversion

#pragma mark 初始化------------

/// 启动初始化语音程序
+ (void)VoiceInitialize
{
    // 设置sdk的log等级，log保存在下面设置的工作路径中
    [IFlySetting setLogFile:LVL_ALL];
    
#warning 发布时设置成NO
    // 打开输出在console的log开关（发布时，设置成NO）
    [IFlySetting showLogcat:YES];
    
    // 设置sdk的工作路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    [IFlySetting setLogFilePath:cachePath];
    
    // Appid是应用的身份信息,具有唯一性,初始化时必须要传入Appid。初始化是一个异步过程,可放在 App 启动时执行初始化,具体代码可以参 照 Demo 的 MSCAppDelegate.m。未初始化时使用服务,一般会返回错误码 10111.
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", VoiceAPPID];
    [IFlySpeechUtility createUtility:initString];
}

#pragma mark 实例化------------

- (void)dealloc
{
    [self voiceCancel];
}

- (NSMutableString *)resultText
{
    if (!_resultText)
    {
        _resultText = [[NSMutableString alloc] init];
    }
    
    return _resultText;
}

- (IFlySpeechRecognizer *)iFlySpeechRecognizer
{
    if (_iFlySpeechRecognizer == nil)
    {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
        
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        // 设置听写模式
        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    }
    
    return _iFlySpeechRecognizer;
}

- (void)initializeVoice
{
    self.iFlySpeechRecognizer.delegate = self;

    IATConfig *instance = [IATConfig sharedInstance];
        
    // 设置最长录音时间
    [self.iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    // 设置后端点
    [self.iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
    // 设置前端点
    [self.iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
    // 网络等待时间
    [self.iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
    
    // 设置采样率，推荐使用16K
    [self.iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
    
    if ([instance.language isEqualToString:[IATConfig chinese]])
    {
        // 设置语言
        [self.iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        // 设置方言
        [self.iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
    }
    else if ([instance.language isEqualToString:[IATConfig english]])
    {
        [self.iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
    }
    
    // 设置是否返回标点符号
    [self.iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
}

#pragma mark 语音听写方法------------

/// 开始录音
- (void)voiceStart:(void (^)(BOOL isStart))startListening speechBegin:(void (^)(void))begin speechEnd:(void (^)(void))end speechError:(void (^)(BOOL isSuccess))error speechResult:(void (^)(NSString *text))result speechVolume:(void (^)(int volume))volume
{
    [self.resultText setString:@""];
    
    // 回调设置
    self.beginSpeech = [begin copy];
    self.endSpeech = [end copy];
    self.errorSpeech = [error copy];
    self.resultSpeech = [result copy];
    self.volumeSpeech = [volume copy];
    
    
    // 初始化设置
    [self initializeVoice];
    
    [self.iFlySpeechRecognizer cancel];
    
    // 设置音频来源为麦克风
    [self.iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
    
    // 设置听写结果格式为json
    [self.iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    
    // 保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
    [self.iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    BOOL isStart = [self.iFlySpeechRecognizer startListening];
    if (startListening)
    {
        // 如果开始录音失败，可能是上次请求未结束，暂不支持多路并发
        startListening(isStart);
    }
}

/// 取消听写
- (void)voiceCancel
{
    [self.iFlySpeechRecognizer cancel];
}

/// 停止录音
- (void)voiceStop
{
    [self.iFlySpeechRecognizer stopListening];
}

#pragma mark IFlySpeechRecognizerDelegate------------

/**
 识别结果返回代理
 @param :results识别结果
 @ param :isLast 表示是否最后一次结果
 */
- (void)onResults:(NSArray *)results isLast:(BOOL)isLast
{
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic)
    {
        [resultString appendFormat:@"%@",key];
    }
    NSString *resultFromJson =  [[self class] stringFromJson:resultString];
    NSString *resultTextTemp = [NSString stringWithFormat:@"%@%@", self.resultText, resultFromJson];
    [self.resultText setString:resultTextTemp];
    
    if (isLast)
    {
        if (self.resultSpeech)
        {
            // 去掉最后一个句号
            NSRange range = [self.resultText rangeOfString:@"。" options:NSBackwardsSearch];
            if (range.location != NSNotFound)
            {
                resultTextTemp = [self.resultText substringToIndex:range.location];
                [self.resultText setString:resultTextTemp];
            }
            self.resultSpeech(self.resultText);
        }
        
        NSLog(@"2 resultString = %@", resultString);
        NSLog(@"2 resultText = %@", self.resultText);
    }
    
    [self voiceCancel];
}

/**
 识别会话结束返回代理
 @ param error 错误码,error.errorCode=0表示正常结束,非0表示发生错误。 
 */
- (void)onError:(IFlySpeechError *)error
{
    if (self.errorSpeech)
    {
        BOOL isSuccess = (0 == error.errorCode);
        self.errorSpeech(isSuccess);
    }
}

/**
 停止录音回调
 */
- (void)onEndOfSpeech
{
    if (self.endSpeech)
    {
        self.endSpeech();
    }
}

/**
 开始录音回调
 */
- (void)onBeginOfSpeech
{
    if (self.beginSpeech)
    {
        self.beginSpeech();
    }
}

/**
 音量回调函数 volume 0-30
 */
- (void)onVolumeChanged:(int)volume
{
    // 如果有连续3秒及以上时间音量为0，则表示停止录音，需要开始进行语音识别了
    [self countDownTheEndTimer:volume];
    
    if (self.volumeSpeech)
    {
        self.volumeSpeech(volume);
    }
}

#pragma mark - 定时器

- (void)countDownTheEnd
{
    self.countDownVolume++;
    
    NSLog(@"countDownVolume = %d", self.countDownVolume);
    
    if (300 == self.countDownVolume)
    {
        [self voiceStop];
        [self killTimer];
        
        if (self.endSpeech && 0 == self.resultText.length)
        {
            self.endSpeech();
        }
    }
}

- (void)countDownTheEndTimer:(int)volume
{
    NSLog(@"volume = %d", volume);
    if (0 == volume)
    {
        [self startTimer];
    }
    else
    {
        [self stopTimer];
    }
}

/// 开启定时器
- (void)startTimer
{
    if (self.countDownTimer == nil)
    {
        self.countDownTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(countDownTheEnd) userInfo:nil repeats:YES];
        
        [self stopTimer];
    }
    
    [self.countDownTimer setFireDate:[NSDate distantPast]];
}

/// 关闭定时器
- (void)stopTimer
{
    self.countDownVolume = 0;
    if (self.countDownTimer)
    {
        [self.countDownTimer setFireDate:[NSDate distantFuture]];
    }
}

/// 永久停止定时器
- (void)killTimer
{
    if (self.countDownTimer)
    {
        [self stopTimer];
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

#pragma mark 解析方法------------

/**************************************************************************/

/**
 解析命令词返回的结果
 */
+ (NSString *)stringFromAsr:(NSString *)params;
{
    NSMutableString * resultString = [[NSMutableString alloc] init];
    NSString *inputString = nil;
    
    NSArray *array = [params componentsSeparatedByString:@"\n"];
    
    for (int index = 0; index < array.count; index++)
    {
        NSRange range;
        NSString *line = [array objectAtIndex:index];
        
        NSRange idRange = [line rangeOfString:@"id="];
        NSRange nameRange = [line rangeOfString:@"name="];
        NSRange confidenceRange = [line rangeOfString:@"confidence="];
        NSRange grammarRange = [line rangeOfString:@" grammar="];
        
        NSRange inputRange = [line rangeOfString:@"input="];
        
        if (confidenceRange.length == 0 || grammarRange.length == 0 || inputRange.length == 0 )
        {
            continue;
        }
        
        // check nomatch
        if (idRange.length != 0)
        {
            NSUInteger idPosX = idRange.location + idRange.length;
            NSUInteger idLength = nameRange.location - idPosX;
            range = NSMakeRange(idPosX, idLength);
            
            NSString *subString = [line substringWithRange:range];
            NSCharacterSet *subSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSString *idValue = [subString stringByTrimmingCharactersInSet:subSet];
            if ([idValue isEqualToString:@"nomatch"])
            {
                return @"";
            }
        }
        
        // Get Confidence Value
        NSUInteger confidencePosX = confidenceRange.location + confidenceRange.length;
        NSUInteger confidenceLength = grammarRange.location - confidencePosX;
        range = NSMakeRange(confidencePosX,confidenceLength);
        
        NSString *score = [line substringWithRange:range];
        
        NSUInteger inputStringPosX = inputRange.location + inputRange.length;
        NSUInteger inputStringLength = line.length - inputStringPosX;
        
        range = NSMakeRange(inputStringPosX , inputStringLength);
        inputString = [line substringWithRange:range];
        
        [resultString appendFormat:@"%@ 置信度%@\n",inputString, score];
    }
    
    return resultString;
}

/**
 解析听写json格式的数据
 params例如：
 {"sn":1,"ls":true,"bg":0,"ed":0,"ws":[{"bg":0,"cw":[{"w":"白日","sc":0}]},{"bg":0,"cw":[{"w":"依山","sc":0}]},{"bg":0,"cw":[{"w":"尽","sc":0}]},{"bg":0,"cw":[{"w":"黄河入海流","sc":0}]},{"bg":0,"cw":[{"w":"。","sc":0}]}]}
 */
+ (NSString *)stringFromJson:(NSString *)params
{
    if (params == NULL)
    {
        return nil;
    }
    
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    // 返回的格式必须为utf8的,否则发生未知错误
    NSData *dataJSON = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:dataJSON options:kNilOptions error:nil];
    
    if (resultDic != nil)
    {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];
        
        for (int i = 0; i < [wordArray count]; i++)
        {
            NSDictionary *wsDic = [wordArray objectAtIndex:i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            
            for (int j = 0; j < [cwArray count]; j++)
            {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString: str];
            }
        }
    }
    
    return tempStr;
}


/**
 解析语法识别返回的结果
 */
+ (NSString *)stringFromABNFJson:(NSString *)params
{
    if (params == NULL)
    {
        return nil;
    }
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    NSData *dataJSON = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:dataJSON options:kNilOptions error:nil];
    
    NSArray *wordArray = [resultDic objectForKey:@"ws"];
    for (int i = 0; i < [wordArray count]; i++)
    {
        NSDictionary *wsDic = [wordArray objectAtIndex:i];
        NSArray *cwArray = [wsDic objectForKey:@"cw"];
        
        for (int j = 0; j < [cwArray count]; j++)
        {
            NSDictionary *wDic = [cwArray objectAtIndex:j];
            NSString *str = [wDic objectForKey:@"w"];
            NSString *score = [wDic objectForKey:@"sc"];
            [tempStr appendString: str];
            [tempStr appendFormat:@" 置信度:%@",score];
            [tempStr appendString: @"\n"];
        }
    }
    
    return tempStr;
}

/**************************************************************************/

@end
