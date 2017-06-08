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

////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface _JRMultipartFormDataImpl : NSObject <JRMultipartFormData>

@property (nonatomic, strong) NSMutableArray<JRUploadFormat *> *formats;

@end

@implementation _JRMultipartFormDataImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        _formats = [NSMutableArray array];
    }
    return self;
}

- (void)appendData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    JRUploadFormat *format = [JRUploadFormat formatWithName:name filename:fileName data:data mimeType:mimeType];
    [_formats addObject:format];
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

#pragma mark - setting method

- (instancetype)constructingData:(void (^)(id<JRMultipartFormData>))constructingBody {
    _JRMultipartFormDataImpl *formData = [_JRMultipartFormDataImpl new];
    constructingBody(formData);
    self->_formats = formData.formats;
    return self;
}

- (instancetype)uploadProgress:(void (^)(NSProgress *))progressBlock {
    self->_uploadProgressBlock = progressBlock;
    return self;
}

- (instancetype)downloadProgress:(void (^)(NSProgress *))progressBlock {
    self->_downloadProgressBlock = progressBlock;
    return self;
}

- (instancetype)success:(JRRequestSuccessBlock)successBlock {
    self->_successBlock = successBlock;
    return self;
}

- (instancetype)failure:(JRRequestFailureBlock)failureBlock {
    self->_failureBlock = failureBlock;
    return self;
}

- (instancetype)resultMap:(JRRequestMapBlock)mapBlock {
    _resultMapBlock = mapBlock;
    return self;
}

- (instancetype)parameters:(NSDictionary *)parameters {
    self->_params = parameters;
    return self;
}

- (instancetype)addValue:(NSString *)value forHeader:(NSString *)header {
    if (value) {
        self.extraHeaders[header] = value;
    }
    return self;
}

#pragma mark - request

- (id<JRRequestTask>)executeRequest {
    return [self executeRequestSuccess:nil failure:nil];
}

- (id<JRRequestTask>)executeRequestSuccess:(JRRequestSuccessBlock)success failure:(JRRequestFailureBlock)failure {
    if (success) {
        self->_successBlock = success;
    }
    if (failure) {
        self->_failureBlock = failure;
    }
    id<JRRequestTask> task = [self getTask];
    [task jr_resume];
    return task;
}

- (id<JRRequestTask>)getTask {

    // 配置请求头
    NSMutableDictionary *headers = self.extraHeaders.mutableCopy;
    NSDictionary *baseHeader = [self getBaseHeaders];
    if (baseHeader.count) {
        [headers addEntriesFromDictionary:baseHeader];
    }

    // 添加mapblock
    JRRequestMapBlock mapBlock = self.resultMapBlock;
    if (mapBlock) {
        JRRequestSuccessBlock success = self.successBlock;
        [self success:^(id<JRRequestTask> task, id responseObj) {
            success(task, mapBlock(responseObj));
        }];
    }

    // 创建任务
    return [self.handler taskWithType:self.requestType
                                  url:self.url
                           parameters:self.params
                              headers:headers
                        uploadFormats:self.formats
                       uploadProgress:self.uploadProgressBlock
                     downloadProgress:self.downloadProgressBlock
                              success:self.successBlock
                              failure:self.failureBlock];
}

#pragma mark - getter

- (id<JRRequestHandler>)handler {
    if (!_handler) {
        _handler = [self getHandler];
    }
    return _handler;
}

@synthesize extraHeaders = _extraHeaders;

- (NSMutableDictionary *)extraHeaders {
    if (!_extraHeaders) {
        _extraHeaders = [NSMutableDictionary dictionary];
    }
    return _extraHeaders;
}

#pragma mark - method should be override

- (id<JRRequestHandler>)getHandler {
    NSAssert(NO, @"在本类【%@】中实现本方法:%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
    return nil;
}

- (NSString *)resolveUrl:(NSString *)oldUrl {
    return oldUrl;
}

- (NSDictionary<NSString *,NSString *> *)getBaseHeaders {
    return nil;
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
