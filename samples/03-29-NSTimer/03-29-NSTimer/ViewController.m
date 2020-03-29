//
//  ViewController.m
//  03-29-NSTimer
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "ViewController.h"
#import "NormalUseViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *gotoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    gotoBtn.frame = CGRectMake(100, 100, 200, 60);
    [gotoBtn setTitle:@"跳转到其他页面" forState:UIControlStateNormal];
    [gotoBtn addTarget:self action:@selector(gotoPage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:gotoBtn];
}

- (void)gotoPage {
    NormalUseViewController *vc = [NormalUseViewController new];
    vc.pt_title = @"第二个页面";
    [self presentViewController:vc animated:true completion:nil];
}


@end
