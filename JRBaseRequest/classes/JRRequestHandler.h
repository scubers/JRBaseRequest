//
//  JRRequestHandler.h
//  JRCampusSocial
//
//  Created by J on 2016/9/26.
//  Copyright © 2016年 HHJR. All rights reserved.
//

#ifndef JRRequestHandler_h
#define JRRequestHandler_h

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

@protocol JRRequestHandler <NSObject>

@required
- (id<JRCancellable>)requestWithType:(JRRequestType)type
                                 url:(NSString *)url
                          parameters:(NSDictionary *)parameters
                            progress:(void (^)(NSProgress *progress))progress
                             success:(void (^)(id<JRCancellable> task, id responseObject))success
                             failure:(void (^)(id<JRCancellable> task, NSError *error))failure;

@optional
- (id<JRCancellable>)uploadFileWithType:(JRRequestType)type
                                    url:(NSString *)url
                             parameters:(NSDictionary *)parameters
                  constructingBodyBlock:(void (^)(id<JRMultipartFormData> formData))constructingBodyBlock
                               progress:(void (^)(NSProgress *progress))progress
                                success:(void (^)(id<JRCancellable> task, id responseObject))success
                                failure:(void (^)(id<JRCancellable> task, NSError *error))failure;


/**
 如需要移除某个key，请设置 @{key : [NSNull null]}

 @param headers headers description
 */
- (void)setupHeaders:(NSDictionary *)headers;

@end



#endif /* JRRequestHandler_h */
