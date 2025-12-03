//
//  AWSS3Uploader.swift
//  Runner
//
//  AWS S3 文件上传器
//

import Foundation
import AWSS3

class AWSS3Uploader {
    
    private let region: AWSRegionType
    private let bucketName: String
    private let endpoint: String?
    
    init(region: String,
         accessKey: String,
         secretKey: String,
         bucketName: String,
         sessionToken: String? = nil,
         endpoint: String? = nil) {
        
        self.region = AWSRegionType.regionTypeValue(from: region)
        self.bucketName = bucketName
        self.endpoint = endpoint
        
        // 创建凭证提供者
        let credentialsProvider: AWSCredentialsProvider
        if let token = sessionToken, !token.isEmpty {
            // 临时凭证
            credentialsProvider = AWSBasicSessionCredentialsProvider(
                accessKey: accessKey,
                secretKey: secretKey,
                sessionToken: token
            )
        } else {
            // 永久凭证
            credentialsProvider = AWSStaticCredentialsProvider(
                accessKey: accessKey,
                secretKey: secretKey
            )
        }
        
        // 创建配置
        var serviceConfiguration: AWSServiceConfiguration
        if let endpointStr = endpoint, !endpointStr.isEmpty {
            // 使用自定义 endpoint
            let customEndpoint = AWSEndpoint(urlString: endpointStr)
            serviceConfiguration = AWSServiceConfiguration(
                region: self.region,
                endpoint: customEndpoint,
                credentialsProvider: credentialsProvider
            )!
        } else {
            serviceConfiguration = AWSServiceConfiguration(
                region: self.region,
                credentialsProvider: credentialsProvider
            )!
        }
        
        // 设置默认配置
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration
        
        NSLog("📦 AWS S3 客户端已创建: \(region)")
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
        let key = objectKey ?? CloudStorageManager.generateObjectKey(fileName: fileName, folder: "aws")
        
        NSLog("📤 开始上传到 AWS S3: \(key)")
        
        // 创建上传表达式
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { task, awsProgress in
            let progressValue = Float(awsProgress.fractionCompleted)
            DispatchQueue.main.async {
                progress?(progressValue)
            }
        }
        
        // 完成回调
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { task, error in
            if let error = error {
                NSLog("❌ AWS S3 上传失败: \(error.localizedDescription)")
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
                let fileUrl: String
                if let endpoint = self.endpoint, !endpoint.isEmpty {
                    let endpointHost = endpoint
                        .replacingOccurrences(of: "https://", with: "")
                        .replacingOccurrences(of: "http://", with: "")
                    fileUrl = "https://\(self.bucketName).\(endpointHost)/\(key)"
                } else {
                    fileUrl = "https://\(self.bucketName).s3.\(self.region.stringValue).amazonaws.com/\(key)"
                }
                
                NSLog("✅ AWS S3 上传成功: \(fileUrl)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: true,
                        url: fileUrl,
                        thumbnailUrl: fileUrl,
                        error: nil
                    ))
                }
            }
        }
        
        // 获取 MIME 类型
        let contentType = CloudStorageManager.getMimeType(for: filePath)
        
        // 获取 TransferUtility
        let transferUtility = AWSS3TransferUtility.default()
        
        // 执行上传
        transferUtility.uploadFile(
            URL(fileURLWithPath: filePath),
            bucket: bucketName,
            key: key,
            contentType: contentType,
            expression: expression,
            completionHandler: completionHandler
        ).continueWith { task -> Any? in
            if let error = task.error {
                NSLog("❌ AWS S3 上传任务创建失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(UploadResult(
                        success: false,
                        url: nil,
                        thumbnailUrl: nil,
                        error: error.localizedDescription
                    ))
                }
            }
            return nil
        }
    }
}

// MARK: - AWSRegionType Extension

extension AWSRegionType {
    static func regionTypeValue(from string: String) -> AWSRegionType {
        switch string.lowercased() {
        case "us-east-1":
            return .USEast1
        case "us-east-2":
            return .USEast2
        case "us-west-1":
            return .USWest1
        case "us-west-2":
            return .USWest2
        case "eu-west-1":
            return .EUWest1
        case "eu-west-2":
            return .EUWest2
        case "eu-central-1":
            return .EUCentral1
        case "ap-northeast-1":
            return .APNortheast1
        case "ap-northeast-2":
            return .APNortheast2
        case "ap-southeast-1":
            return .APSoutheast1
        case "ap-southeast-2":
            return .APSoutheast2
        case "ap-south-1":
            return .APSouth1
        case "sa-east-1":
            return .SAEast1
        case "cn-north-1":
            return .CNNorth1
        case "cn-northwest-1":
            return .CNNorthWest1
        case "ap-east-1":
            return .APEast1
        case "me-south-1":
            return .MESouth1
        case "af-south-1":
            return .AFSouth1
        case "eu-south-1":
            return .EUSouth1
        default:
            return .USEast1
        }
    }
    
    var stringValue: String {
        switch self {
        case .USEast1:
            return "us-east-1"
        case .USEast2:
            return "us-east-2"
        case .USWest1:
            return "us-west-1"
        case .USWest2:
            return "us-west-2"
        case .EUWest1:
            return "eu-west-1"
        case .EUWest2:
            return "eu-west-2"
        case .EUCentral1:
            return "eu-central-1"
        case .APNortheast1:
            return "ap-northeast-1"
        case .APNortheast2:
            return "ap-northeast-2"
        case .APSoutheast1:
            return "ap-southeast-1"
        case .APSoutheast2:
            return "ap-southeast-2"
        case .APSouth1:
            return "ap-south-1"
        case .SAEast1:
            return "sa-east-1"
        case .CNNorth1:
            return "cn-north-1"
        case .CNNorthWest1:
            return "cn-northwest-1"
        case .APEast1:
            return "ap-east-1"
        case .MESouth1:
            return "me-south-1"
        case .AFSouth1:
            return "af-south-1"
        case .EUSouth1:
            return "eu-south-1"
        default:
            return "us-east-1"
        }
    }
}

