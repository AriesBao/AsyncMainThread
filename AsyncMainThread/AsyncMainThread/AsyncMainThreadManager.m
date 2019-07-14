//
//  AsyncMainThreadManager.m
//  AsyncMainThread
//
//  Created by Aries on 2019/7/11.
//  Copyright © 2019 Aries. All rights reserved.
//

#import "AsyncMainThreadManager.h"
#include <mach/mach_time.h>
#include <time.h>
#include <sys/time.h>
#include <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>

#define AsyncMainThreadWaitingDuration (0.01)

static AsyncMainThreadManager * _staticThreadManager;
static double asyncTime = 0;
@interface AsyncMainThreadManager()
@property (nonatomic, strong) NSThread *taskThread;
@property (atomic, copy) NSMutableArray *marrayOfTask;
@end

@implementation AsyncMainThreadManager
{
    CFRunLoopObserverRef _observerBeforeWait;
    CFRunLoopObserverRef _observerAfterWait;
    dispatch_queue_t _queueT;
}


- (void)addTask:(void(^)(void))task
{
    if (task) {
        [self.marrayOfTask addObject:task];
    }
}

- (void)preloadTask
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AsyncMainThreadWaitingDuration * NSEC_PER_SEC)), _queueT, ^{
        [self checkMainThread];
    });
}

- (void)cancelConsume
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkMainThread) object:nil];
}

- (void)consumeTask
{
    void(^task)(void) = [self.marrayOfTask firstObject];
    if (task) {
        dispatch_sync(dispatch_get_main_queue(), task);
        [self.marrayOfTask removeObjectAtIndex:0];
    } else {
        [self removeRunLoopObserver];
    }
}

+(instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _staticThreadManager = [[AsyncMainThreadManager alloc] init];
    });
    return _staticThreadManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _queueT = dispatch_queue_create("AriesThread", NULL);
        _marrayOfTask = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)removeRunLoopObserver
{
    if (_observerBeforeWait && _observerAfterWait) {
        CFRunLoopRef runLoopRef = CFRunLoopGetMain();
        CFRunLoopRemoveObserver(runLoopRef, _observerBeforeWait, kCFRunLoopCommonModes);
        CFRunLoopRemoveObserver(runLoopRef, _observerAfterWait, kCFRunLoopCommonModes);
        CFRelease(_observerBeforeWait);
        CFRelease(_observerAfterWait);
        _observerAfterWait = nil;
        _observerBeforeWait = nil;
    }
}

- (void)addRunLoopObserver
{
    CFRunLoopRef runLoopRef = CFRunLoopGetMain();
    CFRunLoopObserverContext context =  {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    
    _observerBeforeWait = CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0, &runLoopOserverBeforeWaitCallBack,&context);
    
    _observerAfterWait = CFRunLoopObserverCreate(NULL, kCFRunLoopAfterWaiting, YES, 0, &runLoopOserverAfterWaitCallBack,&context);
    
    CFRunLoopAddObserver(runLoopRef, _observerBeforeWait, kCFRunLoopCommonModes);
    CFRunLoopAddObserver(runLoopRef, _observerAfterWait, kCFRunLoopCommonModes);

}

static void runLoopOserverBeforeWaitCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    NSLog(@"runLoopOserverCallBack Before Waiting: ----");
    asyncTime = CACurrentMediaTime();
    [[AsyncMainThreadManager defaultManager] preloadTask];
}

static void runLoopOserverAfterWaitCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    NSLog(@"runLoopOserverCallBack After Waiting: ---- %lf",CACurrentMediaTime() - asyncTime);
    [[AsyncMainThreadManager defaultManager] cancelConsume];
    
}

- (void)checkMainThread
{
    [self consumeTask];
}


@end
