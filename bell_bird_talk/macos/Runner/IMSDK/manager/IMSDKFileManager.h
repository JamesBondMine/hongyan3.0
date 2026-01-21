//
//  IMSDKFileManager.h
//  Runner
//
//  文件上传管理
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 文件管理回调
typedef void (^IMSDKFileCompletion)(int errorCode, NSString * _Nullable message, NSDictionary * _Nullable data, uint64_t reqId);

/// 文件管理器
@interface IMSDKFileManager : NSObject

/// 单例
+ (instancetype)shared;

/// 准备上传文件
/// @param businessModule 业务模块（必填，如: avatar, group_avatar, message等）
/// @param fileName 文件名（必填）
/// @param fileSize 文件大小（字节，可选）
/// @param contentType 文件MIME类型（可选）
/// @param completion 完成回调
/// @return 请求ID，失败返回0
- (uint64_t)prepareUploadWithBusinessModule:(NSString *)businessModule
                                   fileName:(NSString *)fileName
                                   fileSize:(int64_t)fileSize
                                contentType:(nullable NSString *)contentType
                                 completion:(IMSDKFileCompletion)completion;

/// 准备上传文件（简化版）
/// @param businessModule 业务模块
/// @param fileName 文件名
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)prepareUploadWithBusinessModule:(NSString *)businessModule
                                   fileName:(NSString *)fileName
                                 completion:(IMSDKFileCompletion)completion;

@end

NS_ASSUME_NONNULL_END

