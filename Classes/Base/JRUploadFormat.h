//
//  JRUploadFormat.h
//  JRBaseRequest
//
//  Created by 王俊仁 on 2017/5/22.
//  Copyright © 2017年 J. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JRUploadFormat : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *mimeType;

+ (instancetype)formatWithName:(NSString *)name filename:(NSString *)filename data:(NSData *)data mimeType:(NSString *)mimeType;

@end
