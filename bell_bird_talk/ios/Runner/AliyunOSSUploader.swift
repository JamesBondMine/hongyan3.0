//
//  AliyunOSSUploader.swift
//  Runner
//
//  阿里云 OSS 文件上传器
//

import Foundation
import AliyunOSSiOS

class AliyunOSSUploader {
    
    private var client: OSSClient?
    private let endpoint: String
    private let bucketName: String
    
    init(endpoint: String,
         accessKeyId: String,
         accessKeySecret: String,
         bucketName: String,
         securityToken: String? = nil) {
        
        self.endpoint = endpoint
        self.bucketName = bucketName
        
        // 创建凭证提供者
        let credentialProvider: OSSCredentialProvider
        if let token = securityToken, !token.isEmpty {
            // STS 临时凭证
            credentialProvider = OSSStsTokenCredentialProvider(
                accessKeyId: accessKeyId,
                secretKeyId: accessKeySecret,
                securityToken: token
            )
        } else {
            // 永久凭证（不推荐在生产环境使用）
            credentialProvider = OSSPlainTextAKSKPairCredentialProvider(
                plainTextAccessKey: accessKeyId,
                secretKey: accessKeySecret
            )
        }
        
        // 创建客户端配置
        let config = OSSClientConfiguration()
        config.maxRetryCount = 3
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 24 * 60 * 60
        
        // 创建客户端
        self.client = OSSClient(
            endpoint: endpoint,
            credentialProvider: credentialProvider,
            clientConfiguration: config
        )
        
        NSLog("📦 阿里云 OSS 客户端已创建: \(endpoint)")
    }
    
    /// 上传文件
    func upload(filePath: String,
                objectKey: String? = nil,
                progress: ((Float) -> Void)? = nil,
                completion: @escaping (UploadResult) -> Void) {
        
        guard let client = self.client else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "OSS 客户端未初始化"))
            return
        }
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: filePath) else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "文件不存在: \(filePath)"))
            return
        }
        
        // 生成 objectKey
        let fileName = (filePath as NSString).lastPathComponent
        let key = objectKey ?? CloudStorageManager.generateObjectKey(fileName: fileName, folder: "aliyun")
        
        NSLog("📤 开始上传到阿里云 OSS: \(key)")
        
        // 创建上传请求
        let put = OSSPutObjectRequest()
        put.bucketName = bucketName
        put.objectKey = key
        put.uploadingFileURL = URL(fileURLWithPath: filePath)
        
        // 进度回调
        put.uploadProgress = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            let progressValue = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            DispatchQueue.main.async {
                progress?(progressValue)
            }
        }
        
        // 执行上传
        let task = client.putObject(put)
        task.continue({ (task) -> Any? in
            if let error = task.error as NSError? {
                NSLog("❌ 阿里云 OSS 上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: false,
                        url: nil,
                        thumbnailUrl: nil,
                        error: error.localizedDescription
                    ))
                }
            } else {
                // 构建访问 URL
                let endpointHost = self.endpoint
                    .replacingOccurrences(of: "https://", with: "")
                    .replacingOccurrences(of: "http://", with: "")
                let fileUrl = "https://\(self.bucketName).\(endpointHost)/\(key)"
                // 缩略图 URL（阿里云 OSS 图片处理）
                let thumbnailUrl = "\(fileUrl)?x-oss-process=image/resize,h_200,m_lfit"
                
                NSLog("✅ 阿里云 OSS 上传成功: \(fileUrl)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: true,
                        url: fileUrl,
                        thumbnailUrl: thumbnailUrl,
                        error: nil
                    ))
                }
            }
            return nil
        })
    }
    
    /// 更新 STS Token（用于 Token 过期后刷新）
    func updateSTSToken(accessKeyId: String, accessKeySecret: String, securityToken: String) {
        let credentialProvider = OSSStsTokenCredentialProvider(
            accessKeyId: accessKeyId,
            secretKeyId: accessKeySecret,
            securityToken: securityToken
        )
        
        let config = OSSClientConfiguration()
        config.maxRetryCount = 3
        config.timeoutIntervalForRequest = 60
        
        self.client = OSSClient(
            endpoint: endpoint,
            credentialProvider: credentialProvider,
            clientConfiguration: config
        )
        
        NSLog("🔄 阿里云 OSS Token 已更新")
    }
}

