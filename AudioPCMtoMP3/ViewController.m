//
//  ViewController.m
//  AudioPCMtoMP3
//
//  Created by Allan on 3/22/16.
//  Copyright © 2016 zlmg. All rights reserved.
//

#import "ViewController.h"
#import "lame.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *doneButton;

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

- (void)initRecorder {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
