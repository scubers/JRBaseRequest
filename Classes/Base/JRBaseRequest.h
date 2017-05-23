//
//  JRBaseRequest.h
//  JRCampusSocial
//
//  Created by J on 2016/9/19.
//  Copyright © 2016年 HHJR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRRequestHandler.h"
#import "JRUploadFormat.h"

#define JRAssertObjectsNotNil(...) _JRAssertObjectsNotNil(__VA_ARGS__, [NSError errorWithDomain:@"Not_Error" code:0 userInfo:nil])

void _JRAssertObjectsNotNil(id first, ...);

/**
 *  抽象类，不能直接使用，请子类化本类，然后实现 handler 的 getter 方法
 */
@interface JRBaseRequest : NSObject
{
    @protected
    id<JRRequestHandler> _handler;
    NSString *_url;
    NSDictionary *_params;
    NSArray *_urlParams;
}

@property (nonatomic, strong, readonly) NSString *host;
@property (nonatomic, assign) JRRequestType requestType;

@property (nonatomic, strong) id<JRRequestHandler> handler;

@property (nonatomic, strong, readonly) NSString     *url;
@property (nonatomic, strong, readonly) NSDictionary *params;///< 普通分割参数
@property (nonatomic, strong, readonly) NSArray      *urlParams;///< Restful 风格参数

@property (nonatomic, copy  , readonly) JRRequestSuccessBlock successBlock;
@property (nonatomic, copy  , readonly) JRRequestProgressBlock uploadProgressBlock;
@property (nonatomic, copy  , readonly) JRRequestProgressBlock downloadProgressBlock;
@property (nonatomic, copy  , readonly) JRRequestFailureBlock failureBlock;
@property (nonatomic, copy  , readonly) NSArray<JRUploadFormat *> *(^constructingBodyBlock)();


/**
 可变参数为restful风格的url参数

 @param type type description
 @param url url description
 @param params params body中的参数 不能为空
 @return return value description
 */
+ (instancetype)_requestWithType:(JRRequestType)type url:(NSString *)url vaList:(va_list)vaList params:(NSDictionary *)params;

#pragma mark - 普通请求风格创建请求
+ (instancetype)POST:(NSString *)url params:(NSDictionary *)params;
+ (instancetype)GET:(NSString *)url params:(NSDictionary *)params;
+ (instancetype)PUT:(NSString *)url params:(NSDictionary *)params;
+ (instancetype)DELETE:(NSString *)url params:(NSDictionary *)params;

#pragma mark - Restful 风格创建请求 
/**
 *  restful 风格请求 url格式 /api/v1/{userId}/page     参数对应大括号内的参数，参数最后需要插入nil作为结束标识
 *
 *  @param url description
 */
+ (instancetype)POST:(NSString *)url, ...;
/**
 *  restful 风格请求 url格式 /api/v1/{userId}/page     参数对应大括号内的参数，参数最后需要插入nil作为结束标识
 *
 *  @param url description
 */
+ (instancetype)GET:(NSString *)url, ...;
/**
 *  restful 风格请求 url格式 /api/v1/{userId}/page     参数对应大括号内的参数，参数最后需要插入nil作为结束标识
 *
 *  @param url description
 */
+ (instancetype)PUT:(NSString *)url, ...;
/**
 *  restful 风格请求 url格式 /api/v1/{userId}/page     参数对应大括号内的参数，参数最后需要插入nil作为结束标识
 *
 *  @param url description
 */
+ (instancetype)DELETE:(NSString *)url, ...;

#pragma mark - 设置

/**
 *  设置进度block
 *
 *  @param progressBlock description
 *
 */
- (instancetype)uploadProgress:(void (^)(NSProgress *progress))progressBlock;

- (instancetype)downloadProgress:(void (^)(NSProgress *progress))progressBlock;

/**
 *  设置参数
 *
 *  @param parameters description
 */
- (instancetype)parameters:(NSDictionary *)parameters;


- (instancetype)constructingBody:(NSArray<JRUploadFormat *> *(^)())block;

#pragma mark - 创建任务

- (id<JRRequestTask>)getTask;

#pragma mark - 发起请求, 创建任务，并且执行

- (id<JRRequestTask>)startRequestSuccess:(JRRequestSuccessBlock)success failure:(JRRequestFailureBlock)failure;

#pragma mark - subclass override


/**
 子类提供处理器

 @return return value description
 */
- (id<JRRequestHandler>)getHandler;


/**
 处理入参时候的url，返回处理后的url

 @param oldUrl oldUrl description
 @return return value description
 */
- (NSString *)resolveUrl:(NSString *)oldUrl;

@end
