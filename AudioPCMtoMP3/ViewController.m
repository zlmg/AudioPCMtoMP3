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

@property (nonatomic, copy) NSString *audioTemporarySavePath;
@property (nonatomic, copy) NSString *audioFileSavePath;

@end

@implementation ViewController
#pragma mark - init
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.resetButton];
    [self.view addSubview:self.doneButton];
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
    
    NSString *recordTemporaryPathString = [NSString stringWithFormat:@"%@/temporary",self.audioTemporarySavePath];

}

#pragma mark - recorder
- (void)audio_PCMtoMP3
{
    
    NSString *mp3FileName = [self.audioFileSavePath lastPathComponent];
    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    NSString *mp3FilePath = [self.audioTemporarySavePath stringByAppendingPathComponent:mp3FileName];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([self.audioFileSavePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
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
        self.audioFileSavePath = mp3FilePath;
        NSLog(@"MP3生成成功: %@",self.audioFileSavePath);
    }
    
}


#pragma  mark - getter
- (UIButton *)recordButton {
    if (nil == _recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_recordButton setTitle:@"record" forState:UIControlStateNormal];
        [_recordButton setTitle:@"stop" forState:UIControlStateSelected];
        
    }
    return _recordButton;
}

- (UIButton *)playButton {
    if (nil == _playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_playButton setTitle:@"play" forState:UIControlStateNormal];
    }
    return  _playButton;
}

- (UIButton *)resetButton {
    if (nil == _resetButton) {
        _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_resetButton setTitle:@"reset" forState:UIControlStateNormal];
    }
    return _resetButton;
}

- (UIButton *)doneButton {
    if (nil == _doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setTitle:@"done" forState:UIControlStateNormal];
    }
    return  _doneButton;
}

@end
