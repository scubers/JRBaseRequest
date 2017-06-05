//
//  AbstractHttpSessionManager.m
//  Request
//
//  Created by 王俊仁 on 2017/5/27.
//  Copyright © 2017年 J. All rights reserved.
//

#import "AbstractHttpSessionManager.h"

const static NSString *jr_boundary = @"JHkjlkLKUAJHfDFB";

#define JREncodingString(param) [(param) dataUsingEncoding:NSUTF8StringEncoding]

@implementation AbstractHttpSessionManager

- (id<JRRequestTask>)taskWithType:(JRRequestType)type
                              url:(NSString *)url
                       parameters:(NSDictionary *)parameters
                          headers:(NSDictionary *)headers
                    uploadFormats:(NSArray<JRUploadFormat *> *)uploads
                   uploadProgress:(JRRequestProgressBlock)uploadProgress
                 downloadProgress:(JRRequestProgressBlock)downloadProgress
                          success:(JRRequestSuccessBlock)success
                          failure:(JRRequestFailureBlock)failure {

    NSString *newUrl = url;
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        newUrl = [NSString stringWithFormat:@"%@/%@", self.baseURL.absoluteString, url];
    }

    NSError *error;
    NSMutableURLRequest *request = nil;
    if (uploads.count) {
        request = [self.requestSerializer multipartFormRequestWithMethod:[self methodStringWithType:type] URLString:newUrl parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            [uploads enumerateObjectsUsingBlock:^(JRUploadFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [formData appendPartWithFileData:obj.data name:obj.name fileName:obj.filename mimeType:obj.mimeType];
            }];
        } error:&error];
    } else {
        request = [self.requestSerializer requestWithMethod:[self methodStringWithType:type] URLString:newUrl parameters:parameters error:&error];
    }

    if (error) {
        failure(nil, error);
        return nil;
    }

    // 设置请求头的头
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [request addValue:[obj description] forHTTPHeaderField:[key description]];
    }];

    __block NSURLSessionDataTask *task =
    task = [self dataTaskWithRequest:request uploadProgress:uploadProgress downloadProgress:downloadProgress completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            failure(task, error);
        } else {
            success(task, responseObject);
        }
    }];

    return task;
}

- (NSMutableData *)generateBodyDataWithParameters:(NSDictionary *)parameters uploads:(NSArray<JRUploadFormat *> *)uploads {
    NSMutableData *bodyData = [NSMutableData data];

    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"--%@\r\n", jr_boundary]]];
        [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]]];
        [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"%@", obj]]];
        [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"\r\n"]]];
    }];

    // 2. 构建上传参数
    if (uploads.count) {
        [uploads enumerateObjectsUsingBlock:^(JRUploadFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"--%@\r\n", jr_boundary]]];
            [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", obj.name, obj.filename]]];
            [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"]]];
            [bodyData appendData:obj.data];
            [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"\r\n"]]];
        }];
    }

    [bodyData appendData:[self dataWithString:[NSString stringWithFormat:@"--%@--", jr_boundary]]];

    return bodyData;
}

- (NSString *)methodStringWithType:(JRRequestType)type {
    switch (type) {
        case JRRequestTypeGET:return @"GET";
        case JRRequestTypePUT:return @"PUT";
        case JRRequestTypePOST:return @"POST";
        case JRRequestTypeDELETE:return @"DELETE";
        default:return nil;
    }
}

- (NSData *)dataWithString:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark private



@end
