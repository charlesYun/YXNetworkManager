//
//  YXNetworkManager.m
//
//  Created by caoyunxiao on 2020/11/5.
//

#import "YXNetworkManager.h"

static YYCache *_dataCache;
@implementation YXNetworkCache

+ (void)initialize {
    _dataCache = [YYCache cacheWithName:@"YXHttpCache"];
}

#pragma mark - 通过URL和参数写入缓存
+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(id)parameters {
    NSString *cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    [_dataCache setObject:httpData forKey:cacheKey withBlock:nil];
}

#pragma mark - 通过URL和参数获取缓存
+ (id)httpCacheForURL:(NSString *)URL parameters:(id)parameters {
    NSString *cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    return [_dataCache objectForKey:cacheKey];
}

+ (NSInteger)getAllHttpCacheSize {
    return [_dataCache.diskCache totalCost];
}

+ (void)removeAllHttpCache {
    [_dataCache.diskCache removeAllObjects];
}

+ (NSString *)cacheKeyWithURL:(NSString *)URL parameters:(NSDictionary *)parameters {
    if (!parameters || parameters.count == 0) {
        return URL;
    }
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *paraString = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@%@", URL, paraString];
}

@end

static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

@implementation YXNetworkManager

#pragma mark - 初始化AFHTTPSessionManager相关属性
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

#pragma mark - 所有的HTTP请求共享一个AFHTTPSessionManager
+ (void)initialize {
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
}

#pragma mark - 网络监听
+ (void)networkStatusWithBlock:(YXNetworkStatus)networkStatus {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                networkStatus ? networkStatus(YXNetworkStatusUnknown) : nil;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                networkStatus ? networkStatus(YXNetworkStatusNotReachable) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                networkStatus ? networkStatus(YXNetworkStatusReachableViaWWAN) : nil;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                networkStatus ? networkStatus(YXNetworkStatusReachableViaWiFi) : nil;
                break;
        }
    }];
}

+ (YXNetworkStatusType)networkStatus {
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    switch (status) {
        case AFNetworkReachabilityStatusUnknown:
            return YXNetworkStatusUnknown;
        case AFNetworkReachabilityStatusNotReachable:
            return YXNetworkStatusNotReachable;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return YXNetworkStatusReachableViaWWAN;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return YXNetworkStatusReachableViaWiFi;
    }
}

+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL *_Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) return;
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask *_Nonnull task, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - GET请求
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure {
    return [self GET:URL parameters:parameters modelClass:nil responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求 | Model自动解析
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                        modelClass:(Class)model
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure {
    return [self GET:URL parameters:parameters modelClass:model responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求 | 自动缓存
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                     responseCache:(YXHttpRequestCache)responseCache
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure {
    return [self GET:URL parameters:parameters modelClass:nil responseCache:responseCache success:success failure:failure];
}

#pragma mark - GET请求 | 自动缓存 | Model自动解析
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                        modelClass:(Class)model
                     responseCache:(YXHttpRequestCache)responseCache
                           success:(YXHttpRequestSuccess)success
                           failure:(YXHttpRequestFailed)failure {
    return [self request:GET_Method URL:URL parameters:parameters modelClass:model responseCache:responseCache success:success failure:failure];
}

#pragma mark - POST请求
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure {
    return [self POST:URL parameters:parameters modelClass:nil responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求 | Model自动解析
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                         modelClass:(Class)model
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure {
    return [self POST:URL parameters:parameters modelClass:model responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求 | 自动缓存
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                      responseCache:(YXHttpRequestCache)responseCache
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure {
    return [self POST:URL parameters:parameters modelClass:nil responseCache:responseCache success:success failure:failure];
}

#pragma mark - POST请求 | 自动缓存 | Model自动解析
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                         modelClass:(Class)model
                      responseCache:(YXHttpRequestCache)responseCache
                            success:(YXHttpRequestSuccess)success
                            failure:(YXHttpRequestFailed)failure {
    return [self request:POST_Method URL:URL parameters:parameters modelClass:model responseCache:responseCache success:success failure:failure];
}

#pragma mark - 公共请求
+ (__kindof NSURLSessionTask *)request:(NSString *)method
                                   URL:(NSString *)URL
                            parameters:(id)parameters
                            modelClass:(Class)model
                         responseCache:(YXHttpRequestCache)responseCache
                               success:(YXHttpRequestSuccess)success
                               failure:(YXHttpRequestFailed)failure {
    if (responseCache) {
        NSDictionary *cache = [YXNetworkCache httpCacheForURL:URL parameters:parameters];
        if (cache) {
            model ? responseCache([model yy_modelWithDictionary:cache]) : responseCache(cache);
        }
    }
    __block NSURLSessionDataTask *dataTask = [_sessionManager dataTaskWithRequest:[self getEncryptRequest:method URL:URL parameters:parameters] uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
        [[self allSessionTask] removeObject:dataTask];
        if (error) {
            [self analysisError:error dataTask:dataTask failure:failure];
        } else {
            if (success) {
                [self analysisResponseObject:responseObject dataTask:dataTask success:^(id response) {
                    model ? success([model yy_modelWithDictionary:response]) : success(response);
                } failure:^(NSError *error) {
                    [self analysisError:error dataTask:dataTask failure:failure];
                }];
            }
            responseCache ? [YXNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        }
    }];
    [dataTask resume];
    dataTask ? [[self allSessionTask] addObject:dataTask] : nil;
    return dataTask;
}

#pragma mark - 下载文件
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                       fileDir:(NSString *)fileDir
                                      progress:(YXDownloadProgress)progress
                                       success:(void (^)(NSString *filePath))success
                                       failure:(YXHttpRequestFailed)failure {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress *_Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
                          progress ? progress(downloadProgress) : nil;
                      });
    } destination:^NSURL *_Nonnull (NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
        if (fileDir) {
            return [NSURL fileURLWithPath:fileDir];
        }
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (error) {
            failure ? failure(error) : nil;
        }else {
            success ? success(filePath.path) : nil;
        }
    }];
    [downloadTask resume];
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    return downloadTask;
}

/*------------------------------------------子类需重写------------------------------------------*/
+ (NSURLRequest *)getEncryptRequest:(NSString *)method URL:(NSString *)URL parameters:(id)parameters {
    NSAssert(NO, @"子类需重写此方法");
    //example
    NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
    [headerDict setValue:@"application/json" forKey:@"Content-Type"];
    NSMutableURLRequest *urlRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:method URLString:[self getFullRequestURL:URL] parameters:parameters error:nil];
    [urlRequest setAllHTTPHeaderFields:headerDict];
    if (parameters && [method isEqualToString:POST_Method]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
        [urlRequest setHTTPBody:data];
    }
    return urlRequest;
}

+ (NSString *)getFullRequestURL:(NSString *)URL {
    NSAssert(NO, @"子类需重写此方法");
    //example
    return [NSString stringWithFormat:@"%@%@", @"BaseUrl", URL];
}

+ (void)analysisResponseObject:(id)responseObject dataTask:(NSURLSessionDataTask *)dataTask success:(YXHttpRequestSuccess)success failure:(YXHttpRequestFailed)failure {
    NSAssert(NO, @"子类需重写此方法");
    //example
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    NSInteger code = [responseDict[@"code"] integerValue];
    if (code == 200) {
        success(responseDict);
    } else {
        NSError *error = [NSError errorWithDomain:@"BaseUrl" code:code userInfo:@{ NSLocalizedDescriptionKey: responseDict[@"message"] }];
        failure(error);
    }
}

+ (void)analysisError:(NSError *)error dataTask:(NSURLSessionDataTask *)dataTask failure:(YXHttpRequestFailed)failure {
    NSAssert(NO, @"子类需重写此方法");
    //example
    failure(error);
}

#pragma mark - lazy
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

@end
