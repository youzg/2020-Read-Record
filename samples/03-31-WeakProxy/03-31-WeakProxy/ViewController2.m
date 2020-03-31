//
//  ViewController2.m
//  03-31-WeakProxy
//
//  Created by pmst on 2020/4/1.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "ViewController2.h"
#import "YYWeakProxy.h"
static __weak NSTimer *weakTimer = nil;

@interface ViewController2 ()
@property(nonatomic, strong)NSTimer *timer;
@end

@implementation ViewController2


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"--> weakTimer:%@",weakTimer);
    self.view.backgroundColor = [UIColor whiteColor];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:[YYWeakProxy proxyWithTarget:self] selector:@selector(tick1) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    weakTimer = self.timer;
}

- (void)tick {
    static int idx = 0;
    NSLog(@"--->%d",idx++);
}

- (void)dealloc {
    [self.timer invalidate]; // Runloop 会移除 strong 关系，且对其进行 release 操作
    self.timer = nil;
    NSLog(@"dealloc");
}

@end
