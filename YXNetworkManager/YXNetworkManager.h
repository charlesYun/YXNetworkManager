//
//  YXNetworkManager.h
//
//  Created by caoyunxiao on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <YYCache/YYCache.h>
#import <YYModel/YYModel.h>

#define POST_Method @"POST"
#define GET_Method  @"GET"

typedef NS_ENUM (NSUInteger, YXNetworkStatusType) {
    /// 未知网络
    YXNetworkStatusUnknown,
    /// 无网络
    YXNetworkStatusNotReachable,
    /// 手机网络
    YXNetworkStatusReachableViaWWAN,
    /// WiFi
    YXNetworkStatusReachableViaWiFi
};

/// 文件下载进度（progress.completedUnitCount:当前大小，progress.totalUnitCount:总大小）
typedef void (^YXDownloadProgress)(NSProgress *progress);

/// 成功回调
typedef void (^YXHttpRequestSuccess)(id response);

/// 失败回调
typedef void (^YXHttpRequestFailed)(NSError *error);

/// 缓存回调
typedef void (^YXHttpRequestCache)(id responseCache);

/// 网络状态回调
typedef void (^YXNetworkStatus)(YXNetworkStatusType status);

/// 网络请求缓存类
@interface YXNetworkCache : NSObject

/// 通过URL和参数写入缓存
/// @param httpData 服务器返回数据
/// @param URL 请求地址
/// @param parameters 参数
+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(id)parameters;

/// 通过URL和参数获取缓存
/// @param URL 请求地址
/// @param parameters 参数
+ (id)httpCacheForURL:(NSString *)URL parameters:(id)parameters;

/// 获取网络缓存的总大小 bytes(字节)
+ (NSInteger)getAllHttpCacheSize;

/// 删除所有网络缓存
+ (void)removeAllHttpCache;

@end

@class AFHTTPSessionManager;
/// 网络请求类
@interface YXNetworkManager : NSObject

/// 取消所有请求
+ (void)cancelAllRequest;

/// 取消指定URL的请求
+ (void)cancelRequestWithURL:(NSString *)URL;

/// 实时获取网络状态,通过Block回调实时获取
+ (void)networkStatusWithBlock:(YXNetworkStatus)networkStatus;

/// 获取当前网络状态
+ (YXNetworkStatusType)networkStatus;

/// GET请求
/// @param URL 请求地址
/// @param parameters 参数
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure;

/// GET请求 |  Model自动解析
/// @param URL 请求地址
/// @param parameters 参数
/// @param model 解析对象
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                        modelClass:(Class)model
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure;

/// GET请求 | 自动缓存
/// @param URL 请求地址
/// @param parameters 参数
/// @param responseCache 如果有缓存会先回调
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                     responseCache:(YXHttpRequestCache)responseCache
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure;

/// GET请求 | 自动缓存 |  Model自动解析
/// @param URL 请求地址
/// @param parameters 参数
/// @param model 解析对象
/// @param responseCache 如果有缓存会先回调
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                        modelClass:(Class)model
                     responseCache:(YXHttpRequestCache)responseCache
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure;

/// POST请求
/// @param URL 请求地址
/// @param parameters 参数
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure;

/// POST请求 | Model自动解析
/// @param URL 请求地址
/// @param parameters 参数
/// @param model 解析对象
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                         modelClass:(Class)model
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure;

/// POST请求 | 自动缓存
/// @param URL 请求地址
/// @param parameters 参数
/// @param responseCache 如果有缓存会先回调
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                      responseCache:(YXHttpRequestCache)responseCache
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure;

/// POST请求 | 自动缓存 |  Model自动解析
/// @param URL 请求地址
/// @param parameters 参数
/// @param model 解析对象
/// @param responseCache 如果有缓存会先回调
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                         modelClass:(Class)model
                      responseCache:(YXHttpRequestCache)responseCache
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure;

/// 下载文件
/// @param URL 请求地址
/// @param fileDir 指定文件存储目录/文件名（默认存储目录为Library/Caches/Download/下载地址文件名）
/// @param progress 下载进度
/// @param success 成功回调
/// @param failure 失败回调
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                       fileDir:(NSString *)fileDir
                                      progress:(YXDownloadProgress)progress
                                       success:(void (^)(NSString *filePath))success
                                       failure:(YXHttpRequestFailed)failure;

/*------------------------------------------子类需重写------------------------------------------*/
/// 获取NSMutableURLRequest  自定义 请求加密 / 添加请求头 / HTTPBody 等等
/// @param method 请求类型
/// @param URL 地址
/// @param parameters 参数
+ (NSURLRequest *)getEncryptRequest:(NSString *)method URL:(NSString *)URL parameters:(id)parameters;

/// 获取完整请求地址
/// @param URL 地址
+ (NSString *)getFullRequestURL:(NSString *)URL;

/// 成功 公共解析
/// @param responseObject 请求数据
/// @param dataTask 请求信息
/// @param success 成功回调
/// @param failure 失败回调
+ (void)analysisResponseObject:(id)responseObject dataTask:(NSURLSessionDataTask *)dataTask success:(YXHttpRequestSuccess)success failure:(YXHttpRequestFailed)failure;

/// 失败 公共解析
/// @param error 错误数据
/// @param dataTask 请求信息
/// @param failure 失败回调
+ (void)analysisError:(NSError *)error dataTask:(NSURLSessionDataTask *)dataTask failure:(YXHttpRequestFailed)failure;

@end
