//
//  IMSDKFileManager.mm
//  Runner
//
//  文件上传管理实现
//

#import "IMSDKFileManager.h"
#import "network_lib.h"
#import "FilePb.pbobjc.h"
#import <UIKit/UIKit.h>

// 存储回调的字典
static NSMutableDictionary<NSNumber *, IMSDKFileCompletion> *g_fileCallbacks = nil;

// 准备上传回调
void PrepareUploadCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 准备上传回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // 立即拷贝数据（避免主线程访问时数据已释放）
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKFileCompletion completion = g_fileCallbacks[@(reqId)];
        if (!completion) {
            NSLog(@"⚠️ 未找到回调: reqId=%llu", reqId);
            return;
        }
        
        [g_fileCallbacks removeObjectForKey:@(reqId)];
        
        if (errorCode != 0) {
            NSString *errorMsg = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"准备上传失败";
            completion(errorCode, errorMsg, nil, reqId);
            return;
        }
        
        // 解析返回的 Token 信息
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        
        if (responseData && responseData.length > 0) {
            NSError *error = nil;
            Token *token = [Token parseFromData:responseData error:&error];
            
            if (token && !error) {
                result[@"provider_code"] = token.providerCode ?: @"";
                result[@"upload_url"] = token.uploadURL ?: @"";
                result[@"method"] = token.method ?: @"";
                result[@"file_path"] = token.filePath ?: @"";
                result[@"file_url"] = token.fileURL ?: @"";
                result[@"expires_at"] = @(token.expiresAt);
                result[@"expires_in"] = @(token.expiresIn);
                result[@"upload_mode"] = token.uploadMode ?: @"";
                result[@"bucket_name"] = token.bucketName ?: @"";
                result[@"region"] = token.region ?: @"";
                
                // STS 临时凭证
                result[@"sts_access_key_id"] = token.stsAccessKeyId ?: @"";
                result[@"sts_access_key_secret"] = token.stsAccessKeySecret ?: @"";
                result[@"sts_security_token"] = token.stsSecurityToken ?: @"";
                result[@"sts_expiration"] = token.stsExpiration ?: @"";
                
                // Headers (map)
                if (token.headers && token.headers.count > 0) {
                    result[@"headers"] = [token.headers copy];
                } else {
                    result[@"headers"] = @{};
                }
                
                // FormData (map)
                if (token.formData && token.formData.count > 0) {
                    result[@"form_data"] = [token.formData copy];
                } else {
                    result[@"form_data"] = @{};
                }
                
                NSLog(@"✅ 准备上传成功: provider=%@, uploadUrl=%@, fileUrl=%@", 
                      token.providerCode, token.uploadURL, token.fileURL);
            } else {
                NSLog(@"⚠️ 解析 Token 失败: %@", error);
                // 尝试返回原始数据
                NSString *rawData = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                if (rawData) {
                    result[@"raw_data"] = rawData;
                }
            }
        }
        
        completion(0, @"准备上传成功", result, reqId);
    });
}

@implementation IMSDKFileManager

+ (instancetype)shared {
    static IMSDKFileManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKFileManager alloc] init];
        g_fileCallbacks = [NSMutableDictionary dictionary];
    });
    return instance;
}

- (uint64_t)prepareUploadWithBusinessModule:(NSString *)businessModule
                                   fileName:(NSString *)fileName
                                   fileSize:(int64_t)fileSize
                                contentType:(nullable NSString *)contentType
                                 completion:(IMSDKFileCompletion)completion {
    NSLog(@"📤 准备上传: businessModule=%@, fileName=%@, fileSize=%lld, contentType=%@", 
          businessModule, fileName, fileSize, contentType);
    
    if (!businessModule || businessModule.length == 0) {
        NSLog(@"❌ businessModule 不能为空");
        if (completion) {
            completion(-1, @"业务模块不能为空", nil, 0);
        }
        return 0;
    }
    
    if (!fileName || fileName.length == 0) {
        NSLog(@"❌ fileName 不能为空");
        if (completion) {
            completion(-1, @"文件名不能为空", nil, 0);
        }
        return 0;
    }
    
    // 创建 Prepare 对象
    Prepare *prepare = [[Prepare alloc] init];
    prepare.businessModule = businessModule;
    prepare.fileName = fileName;
    
    if (fileSize > 0) {
        prepare.fileSize = fileSize;
    }
    
    if (contentType && contentType.length > 0) {
        prepare.contentType = contentType;
    }
    
    // 序列化
    NSData *serializedData = [prepare data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化 Prepare 数据失败");
        if (completion) {
            completion(-2, @"序列化失败", nil, 0);
        }
        return 0;
    }
    
    NSLog(@"📦 序列化成功: %lu 字节", (unsigned long)serializedData.length);
    
    // 调用 SDK
    uint64_t reqId = 0;
    int result = prepare_upload(PrepareUploadCallback,
                                (const char *)serializedData.bytes,
                                (int)serializedData.length,
                                reqId);
    
    if (result == 0 && reqId > 0) {
        if (completion) {
            g_fileCallbacks[@(reqId)] = [completion copy];
        }
        NSLog(@"✅ 准备上传请求已发送: reqId=%llu", reqId);
    } else {
        NSLog(@"❌ 准备上传请求失败: result=%d", result);
        if (completion) {
            completion(result, @"发送请求失败", nil, 0);
        }
    }
    
    return reqId;
}

- (uint64_t)prepareUploadWithBusinessModule:(NSString *)businessModule
                                   fileName:(NSString *)fileName
                                 completion:(IMSDKFileCompletion)completion {
    return [self prepareUploadWithBusinessModule:businessModule
                                        fileName:fileName
                                        fileSize:0
                                     contentType:nil
                                      completion:completion];
}

@end

