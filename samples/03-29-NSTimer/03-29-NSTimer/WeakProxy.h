//
//  WeakProxy.h
//  03-29-NSTimer
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 self.link = [CADisplayLink displayLinkWithTarget:[WeakProxy proxyWith:self] selector:@selector(tick:)];
 [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    持有关系 vc —> timer —> weakproxy - - -> vc 可以看到并没有形成环
 timer = nil 在 ARC 下应该有 release  + 置为 nil 操作
 */
@interface WeakProxy : NSObject
- (instancetype)initWithTarget:(NSObject *)target;
@end

NS_ASSUME_NONNULL_END
