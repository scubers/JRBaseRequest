//
//  JRRequestHandler.h
//  JRCampusSocial
//
//  Created by J on 2016/9/26.
//  Copyright © 2016年 HHJR. All rights reserved.
//

#ifndef JRRequestHandler_h
#define JRRequestHandler_h

@class JRUploadFormat;

typedef NS_ENUM(NSUInteger, JRRequestType) {
    JRRequestTypeGET,
    JRRequestTypePUT,
    JRRequestTypePOST,
    JRRequestTypeDELETE,
};

// ====================

@protocol JRMultipartFormData <NSObject>

@required
- (void)appendData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;


@end

// ================================================================================

@protocol JRCancellable <NSObject>

@required
- (void)jr_cancel;

@end



// ================================================================================

@protocol JRRequestTask <JRCancellable>

- (void)jr_resume;

@end

// ================================================================================

typedef void(^JRRequestSuccessBlock)(id<JRRequestTask> task, id responseObj);
typedef void(^JRRequestProgressBlock)(NSProgress *progress);
typedef void(^JRRequestFailureBlock)(id<JRRequestTask> task, NSError *error);



/**
 产生一个未开始的任务
 */
@protocol JRRequestHandler <NSObject>

@required

- (id<JRRequestTask>)taskWithType:(JRRequestType)type
                              url:(NSString *)url
                       parameters:(NSDictionary *)parameters
                    uploadFormats:(NSArray<JRUploadFormat *> *)uploads
                   uploadProgress:(JRRequestProgressBlock)uploadProgress
                 downloadProgress:(JRRequestProgressBlock)downloadProgress
                          success:(JRRequestSuccessBlock)success
                          failure:(JRRequestFailureBlock)failure;


/**
 如需要移除某个key，请设置 @{key : [NSNull null]}

 @param headers headers description
 */
- (NSDictionary *)getHeaders;



@end



#endif /* JRRequestHandler_h */
