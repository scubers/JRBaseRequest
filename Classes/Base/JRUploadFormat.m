//
//  JRUploadFormat.m
//  JRBaseRequest
//
//  Created by 王俊仁 on 2017/5/22.
//  Copyright © 2017年 J. All rights reserved.
//

#import "JRUploadFormat.h"

@implementation JRUploadFormat

+ (instancetype)formatWithName:(NSString *)name filename:(NSString *)filename data:(NSData *)data mimeType:(NSString *)mimeType {
    JRUploadFormat *format = [[self alloc] init];
    format.name = name;
    format.filename = filename;
    format.data = data;
    format.mimeType = mimeType;
    return format;
}

@end
