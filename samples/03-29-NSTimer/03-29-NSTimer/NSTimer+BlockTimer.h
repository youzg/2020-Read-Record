//
//  NSTimer+BlockTimer.h
//  03-29-NSTimer
//
//  Created by pmst on 2020/3/29.
//  Copyright © 2020 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (BlockTimer)
+ (NSTimer *)bl_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)repeats;
@end

NS_ASSUME_NONNULL_END
