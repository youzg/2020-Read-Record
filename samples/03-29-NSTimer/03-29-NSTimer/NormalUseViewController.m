//
//  NormalUseViewController.m
//  03-29-NSTimer
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "NormalUseViewController.h"

@interface NormalUseViewController ()
@property(nonatomic, strong)NSTimer *strongTimer;
@property(nonatomic, weak)NSTimer *weakTimer;
@property(nonatomic, strong)UILabel *label;
@end

@implementation NormalUseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.pt_title;
    self.view.backgroundColor = [UIColor lightGrayColor];
    /// 测试 strong 持有
//    self.strongTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.strongTimer forMode:NSRunLoopCommonModes];
//
    /// 测试 weak 持有
    NSTimer *timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(timerFired) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.weakTimer = timer;
    
    self.label.frame = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 100, 100);
    self.label.text = @"计数开始>";
    self.label.textColor = UIColor.redColor;
    [self.view addSubview:self.label];
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    stopBtn.frame = CGRectMake(100, 100, 100, 60);
    [stopBtn setTitle:@"关闭定时器" forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
}

- (void)stop {
    /**
     This method is the only way to remove a timer from an NSRunLoop object. The NSRunLoop object removes its strong reference to the timer, either just before the invalidate method returns or at some later point.
     If it was configured with target and user info objects, the receiver removes its strong references to those objects as well.
     */
    [self.weakTimer invalidate];
    self.weakTimer = nil;
}

- (UILabel *)label {
    if (_label == nil) {
        _label = [[UILabel alloc] init];
    }
    return _label;
}
- (void)timerFired {
    static int cnt = 0;
    self.label.text = [NSString stringWithFormat:@"计数:%d",cnt++];
}


- (void)dealloc {
    
    NSLog(@"NormalUseViewController dealloc");
}

@end
