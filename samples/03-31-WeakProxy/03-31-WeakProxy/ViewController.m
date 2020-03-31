//
//  ViewController.m
//  03-31-WeakProxy
//
//  Created by pmst on 2020/3/31.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "ViewController.h"
#import "ViewController2.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)gotoChildPage:(id)sender {
    ViewController2 *vc2 = [[ViewController2 alloc] init];
    [self.navigationController pushViewController:vc2 animated:YES];
}

@end
