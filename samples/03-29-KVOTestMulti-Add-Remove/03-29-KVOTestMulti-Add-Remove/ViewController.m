//
//  ViewController.m
//  03-29-KVOTestMulti-Add-Remove
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "ViewController.h"

@interface Person : NSObject
@property(nonatomic, strong)NSString *name;
@property(nonatomic, assign)NSInteger age;
@end

@implementation Person

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age{
    self = [super init];
    if (self) {
        _name = name;
        _age = age;
    }
    return self;
}

@end

@interface KVOMiddleWare : NSObject
@end

@implementation KVOMiddleWare

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"监听到 person 修改属性 %@ 值：%@",keyPath, change[NSKeyValueChangeNewKey]);
}

@end

static __weak KVOMiddleWare *middle = nil;

@interface ViewController ()
@property(nonatomic, strong)Person *person;
@property(nonatomic, strong)KVOMiddleWare *kvohelper;
@property(nonatomic, strong)NSPointerArray *weakArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    
    self.person = [[Person alloc] initWithName:@"pmst" age:18];
    self.kvohelper = [KVOMiddleWare new];
    middle = self.kvohelper;
    NSLog(@"middle ware for kvo :%@",middle);
    [self.person addObserver: middle forKeyPath:@"name" options:options context:nil];
    [self.person addObserver:self forKeyPath:@"age" options:options context:nil];
    [self.person addObserver:self forKeyPath:@"age" options:options context:nil];
    
    self.person.name =  @"pmst2";
    self.person.age = 28;
    
    self.weakArray = [NSPointerArray weakObjectsPointerArray];
    [self.weakArray addPointer: (__bridge void * _Nullable)(self.kvohelper)];
    KVOMiddleWare *local = [KVOMiddleWare new];
    
    [self.weakArray addPointer:(__bridge void * _Nullable)(local)];
    
    [self.weakArray addPointer:(__bridge void * _Nullable)(middle)];
    
    [self.weakArray addPointer:(__bridge void * _Nullable)(self.person)];
    
    NSLog(@"===> self.weakArray is %@",self.weakArray);
    for (int i = 0; i < self.weakArray.count; i++) {
        NSLog(@"===> self.weakArray[%d] = %@", i, [self.weakArray pointerAtIndex:i]);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.kvohelper = nil; // 释放
    
//    self.person.name = @"ppp";
    
    NSLog(@"===> viewDidAppear self.weakArray is %@",self.weakArray);
    for (int i = 0; i < self.weakArray.count; i++) {
        NSLog(@"===> viewDidAppear self.weakArray[%d] = %@", i,[self.weakArray pointerAtIndex:i]);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.person) {
        NSLog(@"监听到 person 修改属性 %@ 值：%@",keyPath, change[NSKeyValueChangeNewKey]);
    } else {
        NSLog(@"非预期的KVO通知");
    }
}


@end
