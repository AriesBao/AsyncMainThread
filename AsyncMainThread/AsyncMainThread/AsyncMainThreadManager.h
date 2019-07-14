//
//  AsyncMainThreadManager.h
//  AsyncMainThread
//
//  Created by Aries on 2019/7/11.
//  Copyright © 2019 Aries. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AsyncMainThreadManager : NSObject

+(instancetype)defaultManager;

- (void)addTask:(void(^)(void))task;

- (void)addRunLoopObserver;

@end

NS_ASSUME_NONNULL_END
