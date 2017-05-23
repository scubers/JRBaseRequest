//
//  NSURLSessionDataTask+JRCancellable.m
//  GameGuess_CN
//
//  Created by J on 2016/10/8.
//  Copyright © 2016年 gaoqi. All rights reserved.
//

#import "NSURLSessionTask+JRCancellable.h"

@implementation NSURLSessionTask (JRCancellable)

- (void)jr_cancel {
    [self cancel];
}

- (void)jr_resume {
    [self resume];
}

@end
