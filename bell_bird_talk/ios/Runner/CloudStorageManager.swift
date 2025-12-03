//
//  CloudStorageManager.swift
//  Runner
//
//  云存储管理器 - 统一管理阿里云OSS、腾讯云COS、AWS S3
//

import Foundation
import Flutter

/// 云存储类型
enum CloudStorageType: String {
    case aliyun = "aliyun"
    case tencent = "tencent"
    case aws = "aws"
}

/// 上传结果
struct UploadResult {
    let success: Bool
    let url: String?
    let thumbnailUrl: String?
    let error: String?
}

/// 云存储管理器
class CloudStorageManager: NSObject {
    
    static let shared = CloudStorageManager()
    
    // 上传器实例
    private var aliyunUploader: AliyunOSSUploader?
    private var tencentUploader: TencentCOSUploader?
    private var awsUploader: AWSS3Uploader?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 初始化方法
    
    /// 初始化阿里云 OSS
    func initAliyun(endpoint: String,
                    accessKeyId: String,
                    accessKeySecret: String,
                    bucketName: String,
                    securityToken: String? = nil) -> Bool {
        aliyunUploader = AliyunOSSUploader(
            endpoint: endpoint,
            accessKeyId: accessKeyId,
            accessKeySecret: accessKeySecret,
            bucketName: bucketName,
            securityToken: securityToken
        )
        NSLog("✅ 阿里云 OSS 初始化完成")
        return true
    }
    
    /// 初始化腾讯云 COS
    func initTencent(region: String,
                     secretId: String,
                     secretKey: String,
                     bucketName: String,
                     token: String? = nil) -> Bool {
        tencentUploader = TencentCOSUploader(
            region: region,
            secretId: secretId,
            secretKey: secretKey,
            bucketName: bucketName,
            token: token
        )
        NSLog("✅ 腾讯云 COS 初始化完成")
        return true
    }
    
    /// 初始化 AWS S3
    func initAWS(region: String,
                 accessKey: String,
                 secretKey: String,
                 bucketName: String,
                 sessionToken: String? = nil,
                 endpoint: String? = nil) -> Bool {
        awsUploader = AWSS3Uploader(
            region: region,
            accessKey: accessKey,
            secretKey: secretKey,
            bucketName: bucketName,
            sessionToken: sessionToken,
            endpoint: endpoint
        )
        NSLog("✅ AWS S3 初始化完成")
        return true
    }
    
    // MARK: - 上传方法
    
    /// 上传到阿里云 OSS
    func uploadToAliyun(filePath: String,
                        objectKey: String? = nil,
                        progress: ((Float) -> Void)? = nil,
                        completion: @escaping (UploadResult) -> Void) {
        guard let uploader = aliyunUploader else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "阿里云 OSS 未初始化"))
            return
        }
        uploader.upload(filePath: filePath, objectKey: objectKey, progress: progress, completion: completion)
    }
    
    /// 上传到腾讯云 COS
    func uploadToTencent(filePath: String,
                         objectKey: String? = nil,
                         progress: ((Float) -> Void)? = nil,
                         completion: @escaping (UploadResult) -> Void) {
        guard let uploader = tencentUploader else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "腾讯云 COS 未初始化"))
            return
        }
        uploader.upload(filePath: filePath, objectKey: objectKey, progress: progress, completion: completion)
    }
    
    /// 上传到 AWS S3
    func uploadToAWS(filePath: String,
                     objectKey: String? = nil,
                     progress: ((Float) -> Void)? = nil,
                     completion: @escaping (UploadResult) -> Void) {
        guard let uploader = awsUploader else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "AWS S3 未初始化"))
            return
        }
        uploader.upload(filePath: filePath, objectKey: objectKey, progress: progress, completion: completion)
    }
    
    // MARK: - 下载方法
    
    /// 下载文件
    func downloadFile(url: String,
                      savePath: String,
                      progress: ((Float) -> Void)? = nil,
                      completion: @escaping (Bool, String?) -> Void) {
        guard let downloadUrl = URL(string: url) else {
            completion(false, "无效的 URL")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: downloadUrl) { tempUrl, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let tempUrl = tempUrl else {
                completion(false, "下载失败")
                return
            }
            
            do {
                let fileManager = FileManager.default
                let destinationUrl = URL(fileURLWithPath: savePath)
                
                // 创建目录
                let directory = destinationUrl.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: directory.path) {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                }
                
                // 如果文件已存在，删除
                if fileManager.fileExists(atPath: savePath) {
                    try fileManager.removeItem(atPath: savePath)
                }
                
                // 移动文件
                try fileManager.moveItem(at: tempUrl, to: destinationUrl)
                completion(true, nil)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
        task.resume()
    }
    
    // MARK: - 辅助方法
    
    /// 生成唯一的 objectKey
    static func generateObjectKey(fileName: String, folder: String = "uploads") -> String {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)
        let ext = (fileName as NSString).pathExtension
        return "\(folder)/\(timestamp)_\(uuid).\(ext)"
    }
    
    /// 获取文件 MIME 类型
    static func getMimeType(for path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "pdf":
            return "application/pdf"
        case "doc", "docx":
            return "application/msword"
        case "xls", "xlsx":
            return "application/vnd.ms-excel"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Flutter MethodChannel 处理

extension CloudStorageManager {
    
    /// 处理 Flutter 调用
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        let args = call.arguments as? [String: Any] ?? [:]
        
        switch method {
        // 初始化
        case "initAliyunOSS":
            handleInitAliyun(args: args, result: result)
        case "initTencentCOS":
            handleInitTencent(args: args, result: result)
        case "initAWSS3":
            handleInitAWS(args: args, result: result)
            
        // 上传
        case "uploadToAliyun":
            handleUploadToAliyun(args: args, result: result)
        case "uploadToTencent":
            handleUploadToTencent(args: args, result: result)
        case "uploadToAWS":
            handleUploadToAWS(args: args, result: result)
            
        // 下载
        case "downloadFile":
            handleDownloadFile(args: args, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInitAliyun(args: [String: Any], result: @escaping FlutterResult) {
        guard let endpoint = args["endpoint"] as? String,
              let accessKeyId = args["accessKeyId"] as? String,
              let accessKeySecret = args["accessKeySecret"] as? String,
              let bucketName = args["bucketName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少必要参数", details: nil))
            return
        }
        let securityToken = args["securityToken"] as? String
        let success = initAliyun(endpoint: endpoint, accessKeyId: accessKeyId, accessKeySecret: accessKeySecret, bucketName: bucketName, securityToken: securityToken)
        result(success)
    }
    
    private func handleInitTencent(args: [String: Any], result: @escaping FlutterResult) {
        guard let region = args["region"] as? String,
              let secretId = args["secretId"] as? String,
              let secretKey = args["secretKey"] as? String,
              let bucketName = args["bucketName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少必要参数", details: nil))
            return
        }
        let token = args["token"] as? String
        let success = initTencent(region: region, secretId: secretId, secretKey: secretKey, bucketName: bucketName, token: token)
        result(success)
    }
    
    private func handleInitAWS(args: [String: Any], result: @escaping FlutterResult) {
        guard let region = args["region"] as? String,
              let accessKey = args["accessKey"] as? String,
              let secretKey = args["secretKey"] as? String,
              let bucketName = args["bucketName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少必要参数", details: nil))
            return
        }
        let sessionToken = args["sessionToken"] as? String
        let endpoint = args["endpoint"] as? String
        let success = initAWS(region: region, accessKey: accessKey, secretKey: secretKey, bucketName: bucketName, sessionToken: sessionToken, endpoint: endpoint)
        result(success)
    }
    
    private func handleUploadToAliyun(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少 filePath 参数", details: nil))
            return
        }
        let objectKey = args["objectKey"] as? String
        
        uploadToAliyun(filePath: filePath, objectKey: objectKey) { uploadResult in
            if uploadResult.success {
                result([
                    "success": true,
                    "url": uploadResult.url ?? "",
                    "thumbnailUrl": uploadResult.thumbnailUrl ?? ""
                ])
            } else {
                result(FlutterError(code: "UPLOAD_FAILED", message: uploadResult.error, details: nil))
            }
        }
    }
    
    private func handleUploadToTencent(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少 filePath 参数", details: nil))
            return
        }
        let objectKey = args["objectKey"] as? String
        
        uploadToTencent(filePath: filePath, objectKey: objectKey) { uploadResult in
            if uploadResult.success {
                result([
                    "success": true,
                    "url": uploadResult.url ?? "",
                    "thumbnailUrl": uploadResult.thumbnailUrl ?? ""
                ])
            } else {
                result(FlutterError(code: "UPLOAD_FAILED", message: uploadResult.error, details: nil))
            }
        }
    }
    
    private func handleUploadToAWS(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少 filePath 参数", details: nil))
            return
        }
        let objectKey = args["objectKey"] as? String
        
        uploadToAWS(filePath: filePath, objectKey: objectKey) { uploadResult in
            if uploadResult.success {
                result([
                    "success": true,
                    "url": uploadResult.url ?? "",
                    "thumbnailUrl": uploadResult.thumbnailUrl ?? ""
                ])
            } else {
                result(FlutterError(code: "UPLOAD_FAILED", message: uploadResult.error, details: nil))
            }
        }
    }
    
    private func handleDownloadFile(args: [String: Any], result: @escaping FlutterResult) {
        guard let url = args["url"] as? String,
              let savePath = args["savePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "缺少必要参数", details: nil))
            return
        }
        
        downloadFile(url: url, savePath: savePath) { success, error in
            if success {
                result(["success": true, "path": savePath])
            } else {
                result(FlutterError(code: "DOWNLOAD_FAILED", message: error, details: nil))
            }
        }
    }
}

