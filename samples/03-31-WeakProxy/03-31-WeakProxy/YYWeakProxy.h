//
//  YYWeakProxy.h
//  03-31-WeakProxy
//
//  Created by pmst on 2020/4/1.
//  Copyright © 2020 pmst. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYWeakProxy : NSProxy
@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;

+ (instancetype)proxyWithTarget:(id)target;
@end

NS_ASSUME_NONNULL_END
