//
//  TencentCOSUploader.swift
//  Runner
//
//  腾讯云 COS 文件上传器
//

import Foundation
import QCloudCOSXML

class TencentCOSUploader: NSObject {
    
    private let region: String
    private let bucketName: String
    private var secretId: String
    private var secretKey: String
    private var token: String?
    
    init(region: String,
         secretId: String,
         secretKey: String,
         bucketName: String,
         token: String? = nil) {
        
        self.region = region
        self.secretId = secretId
        self.secretKey = secretKey
        self.bucketName = bucketName
        self.token = token
        
        super.init()
        
        // 配置腾讯云 COS
        setupCOS()
        
        NSLog("📦 腾讯云 COS 客户端已创建: \(region)")
    }
    
    private func setupCOS() {
        // 创建配置
        let configuration = QCloudServiceConfiguration()
        let endpoint = QCloudCOSXMLEndPoint()
        endpoint.regionName = region
        endpoint.useHTTPS = true
        configuration.endpoint = endpoint
        configuration.signatureProvider = self
        
        // 注册服务
        QCloudCOSXMLService.registerDefaultCOSXML(with: configuration)
        QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(with: configuration)
    }
    
    /// 上传文件
    func upload(filePath: String,
                objectKey: String? = nil,
                progress: ((Float) -> Void)? = nil,
                completion: @escaping (UploadResult) -> Void) {
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: filePath) else {
            completion(UploadResult(success: false, url: nil, thumbnailUrl: nil, error: "文件不存在: \(filePath)"))
            return
        }
        
        // 生成 objectKey
        let fileName = (filePath as NSString).lastPathComponent
        let key = objectKey ?? CloudStorageManager.generateObjectKey(fileName: fileName, folder: "tencent")
        
        NSLog("📤 开始上传到腾讯云 COS: \(key)")
        
        // 创建上传请求
        let put = QCloudCOSXMLUploadObjectRequest<AnyObject>()
        put.bucket = bucketName
        put.object = key
        put.body = URL(fileURLWithPath: filePath) as AnyObject
        
        // 设置临时凭证（如果有）
        if let token = self.token, !token.isEmpty {
            let credential = QCloudCredential()
            credential.secretID = secretId
            credential.secretKey = secretKey
            credential.token = token
            put.credential = credential
        }
        
        // 进度回调
        put.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            let progressValue = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            DispatchQueue.main.async {
                progress?(progressValue)
            }
        }
        
        // 完成回调
        put.setFinish { result, error in
            if let error = error {
                NSLog("❌ 腾讯云 COS 上传失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: false,
                        url: nil,
                        thumbnailUrl: nil,
                        error: error.localizedDescription
                    ))
                }
            } else if let result = result as? QCloudUploadObjectResult {
                let fileUrl = result.location ?? ""
                NSLog("✅ 腾讯云 COS 上传成功: \(fileUrl)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: true,
                        url: fileUrl,
                        thumbnailUrl: fileUrl, // 腾讯云可以通过参数获取缩略图
                        error: nil
                    ))
                }
            } else {
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: false,
                        url: nil,
                        thumbnailUrl: nil,
                        error: "上传结果为空"
                    ))
                }
            }
        }
        
        // 执行上传
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(put)
    }
    
    /// 更新临时凭证
    func updateCredential(secretId: String, secretKey: String, token: String) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.token = token
        NSLog("🔄 腾讯云 COS Token 已更新")
    }
}

// MARK: - QCloudSignatureProvider

extension TencentCOSUploader: QCloudSignatureProvider {
    
    func signature(with fileds: QCloudSignatureFields!,
                   request: QCloudBizHTTPRequest!,
                   urlRequest urlRequst: NSMutableURLRequest!,
                   compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        
        // 创建凭证
        let credential = QCloudCredential()
        credential.secretID = secretId
        credential.secretKey = secretKey
        if let token = self.token, !token.isEmpty {
            credential.token = token
        }
        
        // 创建签名生成器
        let creator = QCloudAuthentationV5Creator(credential: credential)
        
        // 生成签名
        let signature = creator?.signature(forData: urlRequst)
        continueBlock(signature, nil)
    }
}

