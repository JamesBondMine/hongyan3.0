//
//  StorageAPIHandler.swift
//  Runner
//
//  云存储 API 处理器
//  包括：文件上传、下载、云存储初始化等
//

import Flutter
import Foundation

class StorageAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        // 文件上传准备
        if method == "imPrepareUpload" {
            imPrepareUpload(call: call, result: result)
        }
        // 腾讯云 STS 上传
        else if method == "imUploadWithTencentSTS" {
            imUploadWithTencentSTS(call: call, result: result)
        }
        // 云存储相关方法（阿里云、腾讯云、AWS）
        else if method.hasPrefix("init") || method.hasPrefix("upload") || method.hasPrefix("download") {
            CloudStorageManager.shared.handleMethodCall(call, result: result)
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 文件上传
    
    /// 准备上传文件
    /// 参数:
    ///   - business_module: 业务模块（必填，如: avatar, group_avatar, message等）
    ///   - file_name: 文件名（必填）
    ///   - file_size: 文件大小（字节，可选）
    ///   - content_type: 文件MIME类型（可选）
    private func imPrepareUpload(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let businessModule = args["business_module"] as? String, !businessModule.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "业务模块不能为空", details: nil))
            return
        }
        
        guard let fileName = args["file_name"] as? String, !fileName.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "文件名不能为空", details: nil))
            return
        }
        
        let fileSize = args["file_size"] as? Int64 ?? 0
        let contentType = args["content_type"] as? String
        
        print("📤 准备上传: businessModule=\(businessModule), fileName=\(fileName), fileSize=\(fileSize)")
        
        let reqId = IMSDKFileManager.shared().prepareUpload(withBusinessModule: businessModule,
                                                            fileName: fileName,
                                                            fileSize: fileSize,
                                                            contentType: contentType) { errorCode, message, data, reqId in
            print("AppDeleate 准备上传回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 构建返回数据
            var response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? ""
            ]
            
            if let data = data {
                // 将数据转换为 JSON 字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    response["data"] = jsonString
                }
            }
            
            result(response)
        }
        
        if reqId == 0 {
            result(FlutterError(code: "PREPARE_UPLOAD_ERROR",
                              message: "准备上传请求失败",
                              details: nil))
        }
    }
    
    /// 使用腾讯云 STS 临时凭证上传文件
    /// 参数:
    ///   - local_file_path: 本地文件路径（必填）
    ///   - object_key: 对象键/远程路径（必填）
    ///   - bucket_name: 存储桶名称（必填）
    ///   - region: 区域（必填）
    ///   - secret_id: 临时 AccessKeyId（必填）
    ///   - secret_key: 临时 SecretKey（必填）
    ///   - token: 临时 Token（必填）
    private func imUploadWithTencentSTS(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let localFilePath = args["local_file_path"] as? String, !localFilePath.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "本地文件路径不能为空", details: nil))
            return
        }
        
        guard let objectKey = args["object_key"] as? String, !objectKey.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "对象键不能为空", details: nil))
            return
        }
        
        guard let bucketName = args["bucket_name"] as? String, !bucketName.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "存储桶名称不能为空", details: nil))
            return
        }
        
        guard let region = args["region"] as? String, !region.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "区域不能为空", details: nil))
            return
        }
        
        guard let secretId = args["secret_id"] as? String, !secretId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "SecretId 不能为空", details: nil))
            return
        }
        
        guard let secretKey = args["secret_key"] as? String, !secretKey.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "SecretKey 不能为空", details: nil))
            return
        }
        
        guard let token = args["token"] as? String, !token.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "Token 不能为空", details: nil))
            return
        }
        
        print("📤 腾讯云 STS 上传: localPath=\(localFilePath), objectKey=\(objectKey), bucket=\(bucketName)")
        
        // 创建上传器并上传
        let uploader = TencentCOSUploader(
            region: region,
            secretId: secretId,
            secretKey: secretKey,
            bucketName: bucketName,
            token: token
        )
        
        uploader.upload(filePath: localFilePath, objectKey: objectKey, progress: { progress in
            print("📊 上传进度: \(Int(progress * 100))%")
        }) { uploadResult in
            if uploadResult.success {
                print("AppDeleate 腾讯云上传成功: \(uploadResult.url ?? "")")
                result([
                    "success": true,
                    "url": uploadResult.url ?? "",
                    "error": NSNull()
                ])
            } else {
                print("❌ 腾讯云上传失败: \(uploadResult.error ?? "未知错误")")
                result([
                    "success": false,
                    "url": NSNull(),
                    "error": uploadResult.error ?? "上传失败"
                ])
            }
        }
    }
}
