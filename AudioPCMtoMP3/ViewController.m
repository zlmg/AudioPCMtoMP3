//
//  ViewController.m
//  AudioPCMtoMP3
//
//  Created by Allan on 3/22/16.
//  Copyright © 2016 zlmg. All rights reserved.
//

#import "ViewController.h"
#import "lame.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *doneButton;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, copy) NSString *audioTemporarySavePath;
@property (nonatomic, copy) NSString *audioFileSavePath;

@end

@implementation ViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.resetButton];
    [self.view addSubview:self.doneButton];
    [self _layoutSubviews];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self initRecorder];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    self.audioTemporarySavePath = [ViewController filePath:@"temp.caf"];
    self.audioFileSavePath = [ViewController filePath:@"audio.mp3"];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.audioTemporarySavePath] settings:recordSettings error:nil];
}

#pragma mark - event
- (void)recordAction:(UIButton *)button {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];//得到AVAudioSession单例对象
    button.selected = !button.selected;
    if (button.selected) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];//设置类别,表示该应用同时支持播放和录音
        [audioSession setActive:YES error:nil];//启动音频会话管理,此时会阻断后台音乐的播放.
        [self.recorder prepareToRecord];
        [self.recorder record];
    } else {
        [self.recorder pause];                          //录音停止
        [audioSession setActive:NO error:nil];         //一定要在录音停止以后再关闭音频会话管理（否则会报错），此时会延续后台音乐播放
    }
}

- (void)playAciton:(UIButton *)button {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (self.player.isPlaying) {
        [audioSession setActive:NO error:nil];
        [self.player pause];
    } else {
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:YES error:nil];
        [self.player prepareToPlay];
        self.player.volume = 1;
        [self.player play];
    }
}

- (void)resetAction:(UIButton *)button {
    [self.recorder stop];
}

- (void)doneAction:(UIButton *)button {
    [self audio_PCMtoMP3];
}

#pragma mark - recorder
- (void)audio_PCMtoMP3
{
    @try {
        int read, write;
        
        FILE *pcm = fopen([self.audioTemporarySavePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([self.audioFileSavePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"MP3生成成功: %@",self.audioFileSavePath);
    }
    
}


#pragma  mark - getter
- (AVAudioPlayer *)player {
    if (nil == _player) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.audioTemporarySavePath] error:nil];
    }
    return _player;
}
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
        [_playButton addTarget:self action:@selector(playAciton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _playButton;
}

- (UIButton *)resetButton {
    if (nil == _resetButton) {
        _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_resetButton setTitle:@"reset" forState:UIControlStateNormal];
        [_resetButton addTarget:self action:@selector(resetAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resetButton;
}

- (UIButton *)doneButton {
    if (nil == _doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setTitle:@"done" forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return  _doneButton;
}

#pragma mark - layoutSubviews 
- (void)_layoutSubviews {
    self.recordButton.frame = CGRectMake(20, 200, 60, 60);
    self.playButton.frame = CGRectMake(100, 200, 60, 60);
    self.resetButton.frame = CGRectMake(180, 200, 60, 60);
}

+ (NSString *)filePath:(NSString *)fileName {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    if (fileName && [fileName length] != 0) {
        path = [path stringByAppendingPathComponent:fileName];
    }
    return path;
}

@end
