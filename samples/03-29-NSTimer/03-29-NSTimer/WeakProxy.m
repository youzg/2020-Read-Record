//
//  WeakProxy.m
//  03-29-NSTimer
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import "WeakProxy.h"

@interface WeakProxy()
@property(nonatomic, weak)NSObject *target;
@end

@implementation WeakProxy

- (instancetype)initWithTarget:(NSObject *)target {
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (_target) {
        return [_target respondsToSelector:aSelector];
    }
    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _target;
}

@end
