//
//  ViewController.m
//  AudioDemo
//
//  Created by ZhouLimin on 4/4/16.
//  Copyright © 2016 zlmg. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *switchButton;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, copy) NSString *audioTemporarySavePath;
@property (nonatomic, copy) NSString *audioFileSavePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.resetButton];
    [self.view addSubview:self.doneButton];
    [self.view addSubview:self.switchButton];
    [self addLayout];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self initRecorder];
    });
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    //添加监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:)
                                                 name:@"UIDeviceProximityStateDidChangeNotification"
                                               object:nil];
}

- (void)initRecorder {
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [recordSettings setValue :[NSNumber numberWithFloat:11025.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
//    [recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.audioTemporarySavePath] settings:recordSettings error:nil];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.audioTemporarySavePath] error:nil];
}

#pragma mark - event

///处理监听触发事件
-(void)sensorStateChange:(NSNotificationCenter *)notification;

{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)
        
    {
        NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    else
    {
        NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}



- (void)recordAction:(UIButton *)button {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (self.recorder.isRecording) {
        [self.recorder pause];
        self.recordButton.selected = NO;
    } else {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        [session setActive:YES error:&error];
        [self.recorder prepareToRecord];
        self.recordButton.selected = [self.recorder record];
    }
    
}

- (void)playAction:(UIButton *)button {
    if (self.player.playing) {
        [self.player pause];
        self.playButton.selected = NO;
    } else {
        [self.player prepareToPlay];
        [self.player play];
        self.playButton.selected = YES;
    }
}

- (void)resetAction:(UIButton *)button {
    [self.recorder stop];
    [self.player stop];
}

- (void)doneAciton:(UIButton *)button {
    
}

- (void)switchAction:(UIButton *)button {
    button.selected = !button.selected;
    [self.recorder stop];
    [self.player stop];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (button.selected) {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    }
}


#pragma mark - recorder

#pragma mark - private
- (NSString *)pathWithName:(NSString *)name {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

#pragma  mark - getter
- (UIButton *)recordButton {
    if (nil == _recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_recordButton setTitle:@"record" forState:UIControlStateNormal];
        [_recordButton setTitle:@"stop" forState:UIControlStateSelected];
        [_recordButton addTarget:self action:@selector(recordAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _recordButton;
}

- (UIButton *)playButton {
    if (nil == _playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_playButton setTitle:@"play" forState:UIControlStateNormal];
        [_playButton setTitle:@"stop" forState:UIControlStateSelected];
        [_playButton addTarget:self  action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _playButton;
}

- (UIButton *)resetButton {
    if (nil == _resetButton) {
        _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_resetButton setTitle:@"reset" forState:UIControlStateNormal];
        [_recordButton addTarget:self action:@selector(resetAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resetButton;
}

- (UIButton *)doneButton {
    if (nil == _doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setTitle:@"done" forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneAciton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _doneButton;
}

- (UIButton *)switchButton {
    if (nil == _switchButton) {
        _switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_switchButton setTitle:@"speaker" forState:UIControlStateNormal];
        [_switchButton setTitle:@"earphone" forState:UIControlStateSelected];
        [_switchButton addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchButton;
}

- (NSString *)audioTemporarySavePath {
    if (nil == _audioTemporarySavePath) {
        _audioTemporarySavePath = [self pathWithName:@"AudioTemp"];
        _audioTemporarySavePath = [_audioTemporarySavePath stringByAppendingPathComponent:@"PCMAudio2.caf"];
    }
    return _audioTemporarySavePath;
}

- (NSString *)audioFileSavePath {
    if (nil == _audioFileSavePath) {
        _audioFileSavePath = [self pathWithName:@"AudioMP3"];
        _audioFileSavePath = [_audioFileSavePath stringByAppendingPathComponent:@"MP3Audio.caf"];
    }
    return _audioFileSavePath;
}

#pragma mark - layoutSubviews
- (void)addLayout {
    self.recordButton.frame = CGRectMake(20, 20, 100, 50);
    self.playButton.frame = CGRectMake(20, 100, 100, 50);
    self.resetButton.frame = CGRectMake(20, 180, 100, 50);
    self.doneButton.frame = CGRectMake(20, 260, 100, 50);
    self.switchButton.frame = CGRectMake(20, 340, 100, 50);
}


@end
