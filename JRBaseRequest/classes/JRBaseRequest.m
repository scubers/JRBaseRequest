//
//  JRBaseRequest.m
//  JRCampusSocial
//
//  Created by J on 2016/9/19.
//  Copyright © 2016年 HHJR. All rights reserved.
//

#import "JRBaseRequest.h"

void _JRAssertObjectNotNil(id value, NSString *msg) {
    if (!value) {
        NSLog(@"%@", msg);
        assert(NO);
    }
}

void _JRAssertObjectsNotNil(id first, ...) {
    _JRAssertObjectNotNil(first, @"function: [JRAssertObjectsNotNil] assert some nil value");
    va_list list;
    va_start(list, first);
    id value = va_arg(list, id);
    while (!([value isKindOfClass:[NSError class]] && [[value domain] isEqualToString:@"Not_Error"])) {
        _JRAssertObjectNotNil(value, @"function: [JRAssertObjectsNotNil] assert some nil value");
        value = va_arg(list, id);
    }
    va_end(list);
}

@interface JRBaseRequest ()


@end

@implementation JRBaseRequest

+ (instancetype)_requestWithType:(JRRequestType)type url:(NSString *)url vaList:(va_list)vaList params:(NSDictionary *)params {
    NSArray *array = [self vaListToArray:vaList];
    return [self requestWithType:type url:url params:params paramArray:array];
}

+ (instancetype)requestWithType:(JRRequestType)type url:(NSString *)url params:(NSDictionary *)params paramArray:(NSArray *)paramArray {
    JRBaseRequest *req = [[self alloc] init];
    req->_url = [req resolveUrl:url];
    req->_params = params;
    [req setRequestType:type];
    req->_urlParams = paramArray;
    [req fixUrlParamsIntoUrl];// 处理restful 参数
    return req;
}

+ (instancetype)GET:(NSString *)url params:(NSDictionary *)params {
    return [self requestWithType:JRRequestTypeGET url:url params:params paramArray:nil];
}

+ (instancetype)POST:(NSString *)url params:(NSDictionary *)params {
    return [self requestWithType:JRRequestTypePOST url:url params:params paramArray:nil];
}

+ (instancetype)PUT:(NSString *)url params:(NSDictionary *)params {
    return [self requestWithType:JRRequestTypePUT url:url params:params paramArray:nil];
}

+ (instancetype)DELETE:(NSString *)url params:(NSDictionary *)params {
    return [self requestWithType:JRRequestTypeDELETE url:url params:params paramArray:nil];
}

#pragma mark - Restful style

+ (instancetype)POST:(NSString *)url, ... {
    va_list list;
    va_start(list, url);
    NSArray *array = [self vaListToArray:list];
    va_end(list);
    return [self requestWithType:JRRequestTypePOST url:url params:nil paramArray:array];
}

+ (instancetype)GET:(NSString *)url, ... {
    va_list list;
    va_start(list, url);
    NSArray *array = [self vaListToArray:list];
    va_end(list);
    return [self requestWithType:JRRequestTypeGET url:url params:nil paramArray:array];
}

+ (instancetype)PUT:(NSString *)url, ... {
    va_list list;
    va_start(list, url);
    NSArray *array = [self vaListToArray:list];
    va_end(list);
    return [self requestWithType:JRRequestTypePUT url:url params:nil paramArray:array];
}

+ (instancetype)DELETE:(NSString *)url, ... {
    va_list list;
    va_start(list, url);
    NSArray *array = [self vaListToArray:list];
    va_end(list);
    return [self requestWithType:JRRequestTypeDELETE url:url params:nil paramArray:array];
}

#pragma mark - 文件上传

+ (instancetype)uploadFileForUrl:(NSString *)url params:(NSDictionary *)params constructingBody:(void (^)(id<JRMultipartFormData>))constructingBodyBlock {
    JRBaseRequest *req = [self POST:url params:params];
    req->_constructingBodyBlock = [constructingBodyBlock copy];
    req->_params = params;
    req->_isUpload = YES;
    return req;
}

#pragma mark - setting method

- (instancetype)progressBlock:(void (^)(NSProgress *))progressBlock {
    self->_progressBlock = [progressBlock copy];
    return self;
}

- (instancetype)parameters:(NSDictionary *)parameters {
    self->_params = parameters;
    return self;
}

#pragma mark - request

- (id<JRCancellable>)startRequestSuccess:(void (^)(id<JRCancellable>, id))success failure:(void (^)(id<JRCancellable>, NSError *))failure {
    
    return [self.handler requestWithType:self.requestType url:self.url parameters:self.params progress:^(NSProgress *progress) {
        if (self.progressBlock) {
            self.progressBlock(progress);
        }
    } success:^(id<JRCancellable> task, id responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(id<JRCancellable> task, NSError *error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

- (id<JRCancellable>)startUploadFileSuccess:(void (^)(id<JRCancellable>, id))success failure:(void (^)(id<JRCancellable>, NSError *))failure {
    
    return [self.handler uploadFileWithType:self.requestType url:self.url parameters:self.params constructingBodyBlock:^(id<JRMultipartFormData> formData) {
        if (self.constructingBodyBlock) {
            self.constructingBodyBlock(formData);
        }
    } progress:^(NSProgress *progress) {
        if (self.progressBlock) {
            self.progressBlock(progress);
        }
    } success:^(id<JRCancellable> task, id responseObject) {
        if (success) {
            success(task, responseObject);
        }
    } failure:^(id<JRCancellable> task, NSError *error) {
        if (failure) {
            failure(task, error);
        }
    }];
}

#pragma mark - getter

- (id<JRRequestHandler>)handler {
    if (!_handler) {
        _handler = [self getHandler];
    }
    return _handler;
}

#pragma mark - method should be override

- (id<JRRequestHandler>)getHandler {
    NSAssert(NO, @"在子类中实现本方法:%s", __PRETTY_FUNCTION__);
    return nil;
}

- (NSString *)resolveUrl:(NSString *)oldUrl {
    return _url;
}

#pragma mark - private method

- (void)fixUrlParamsIntoUrl {
    if (self.urlParams.count) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{[^\\{^\\}]*\\}"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        
        // 获取参数
        NSMutableString *modifiedurl = [NSMutableString stringWithFormat:@"%@", self.url];
        NSTextCheckingResult *ret;
        NSMutableArray *array = [self.urlParams mutableCopy];
        while ((ret=[regex firstMatchInString:modifiedurl options:0 range:NSMakeRange(0, modifiedurl.length)])) {
            [modifiedurl replaceCharactersInRange:ret.range
                                       withString:[NSString stringWithFormat:@"%@", array.firstObject]];
            if (array.count) {
                [array removeObjectAtIndex:0];
            }
        };
        self->_urlParams = nil;
        self->_url = modifiedurl;
    }
}

+ (NSArray *)vaListToArray:(va_list)vaList {
    NSMutableArray *array = [NSMutableArray array];
    id value;
    while ((value = va_arg(vaList, id))) {
        [array addObject:value];
    }
    return array.copy;
}

@end
