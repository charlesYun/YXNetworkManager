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
            failure ? failure(error) : nil;
        } else {
            if (success) {
                [self analysisResponseObject:responseObject success:^(id response) {
                    model ? success([model yy_modelWithDictionary:response]) : success(response);
                } failure:^(NSError *error) {
                    failure ? failure(error) : nil;
                }];
            }
            responseCache ? [YXNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        }
    }];
    [dataTask resume];
    dataTask ? [[self allSessionTask] addObject:dataTask] : nil;
    return dataTask;
}

/*------------------------------------------子类需重写------------------------------------------*/
+ (NSURLRequest *)getEncryptRequest:(NSString *)method URL:(NSString *)URL parameters:(id)parameters {
    NSAssert(NO, @"子类需重写此方法");
    return nil;
}

+ (NSString *)getFullRequestURL:(NSString *)URL {
    NSAssert(NO, @"子类需重写此方法");
    return nil;
}

+ (void)analysisResponseObject:(id)responseObject success:(YXHttpRequestSuccess)success failure:(YXHttpRequestFailed)failure {
    NSAssert(NO, @"子类需重写此方法");
}

#pragma mark - lazy
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

@end
