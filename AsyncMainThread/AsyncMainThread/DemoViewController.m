//
//  DemoViewController.m
//  AsyncMainThread
//
//  Created by Aries on 2019/7/11.
//  Copyright © 2019 Aries. All rights reserved.
//

#import "DemoViewController.h"
#import "AsyncMainThreadManager.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor grayColor];
    [self addButton];
    [AsyncMainThreadManager defaultManager];
    
    
    
    
}

- (void)addButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"add Task" forState:UIControlStateNormal];
    button.frame = CGRectMake(100, 100, 100, 100);
    [self.view addSubview:button];
    
    int i = 10000;
    while (i --) {
        [self addTask:nil];
//        [self task];
    }
    [[AsyncMainThreadManager defaultManager] addRunLoopObserver];
}

- (void)addTask:(id)sender
{
    [[AsyncMainThreadManager defaultManager] addTask:^{
        [self task];
    }];
}


- (void)task
{
    NSInteger rand = random();
    NSLog(@"start %ld",(long)rand);
    NSLog(@"%ld",rand * rand);
    NSLog(@"finish %ld",rand);
}


@end
