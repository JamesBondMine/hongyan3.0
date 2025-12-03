import 'dart:io';
import 'package:flutter/services.dart';

/// 云存储服务
/// 支持阿里云 OSS、腾讯云 COS、AWS S3
class CloudStorageService {
  static const MethodChannel _channel = MethodChannel('com.bellbird.talk/method');

  // 单例模式
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  // MARK: - 阿里云 OSS

  /// 初始化阿里云 OSS
  /// [endpoint] - 区域节点，如 oss-cn-hangzhou.aliyuncs.com
  /// [accessKeyId] - 访问密钥 ID
  /// [accessKeySecret] - 访问密钥 Secret
  /// [bucketName] - 存储桶名称
  /// [securityToken] - STS 临时凭证 Token（可选）
  Future<bool> initAliyunOSS({
    required String endpoint,
    required String accessKeyId,
    required String accessKeySecret,
    required String bucketName,
    String? securityToken,
  }) async {
    try {
      final result = await _channel.invokeMethod('initAliyunOSS', {
        'endpoint': endpoint,
        'accessKeyId': accessKeyId,
        'accessKeySecret': accessKeySecret,
        'bucketName': bucketName,
        'securityToken': securityToken,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('❌ 阿里云 OSS 初始化失败: ${e.message}');
      return false;
    }
  }

  /// 上传文件到阿里云 OSS
  /// [filePath] - 本地文件路径
  /// [objectKey] - 存储对象键（可选，不传则自动生成）
  /// 返回上传结果，包含 url 和 thumbnailUrl
  Future<UploadResult> uploadToAliyun({
    required String filePath,
    String? objectKey,
  }) async {
    try {
      final result = await _channel.invokeMethod('uploadToAliyun', {
        'filePath': filePath,
        'objectKey': objectKey,
      });
      return UploadResult.fromMap(result as Map<dynamic, dynamic>);
    } on PlatformException catch (e) {
      return UploadResult(success: false, error: e.message);
    }
  }

  // MARK: - 腾讯云 COS

  /// 初始化腾讯云 COS
  /// [region] - 区域，如 ap-guangzhou
  /// [secretId] - 密钥 ID
  /// [secretKey] - 密钥 Key
  /// [bucketName] - 存储桶名称
  /// [token] - 临时凭证 Token（可选）
  Future<bool> initTencentCOS({
    required String region,
    required String secretId,
    required String secretKey,
    required String bucketName,
    String? token,
  }) async {
    try {
      final result = await _channel.invokeMethod('initTencentCOS', {
        'region': region,
        'secretId': secretId,
        'secretKey': secretKey,
        'bucketName': bucketName,
        'token': token,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('❌ 腾讯云 COS 初始化失败: ${e.message}');
      return false;
    }
  }

  /// 上传文件到腾讯云 COS
  /// [filePath] - 本地文件路径
  /// [objectKey] - 存储对象键（可选，不传则自动生成）
  /// 返回上传结果，包含 url 和 thumbnailUrl
  Future<UploadResult> uploadToTencent({
    required String filePath,
    String? objectKey,
  }) async {
    try {
      final result = await _channel.invokeMethod('uploadToTencent', {
        'filePath': filePath,
        'objectKey': objectKey,
      });
      return UploadResult.fromMap(result as Map<dynamic, dynamic>);
    } on PlatformException catch (e) {
      return UploadResult(success: false, error: e.message);
    }
  }

  // MARK: - AWS S3

  /// 初始化 AWS S3
  /// [region] - 区域，如 us-east-1
  /// [accessKey] - 访问密钥
  /// [secretKey] - 密钥
  /// [bucketName] - 存储桶名称
  /// [sessionToken] - 临时凭证 Token（可选）
  /// [endpoint] - 自定义端点（可选）
  Future<bool> initAWSS3({
    required String region,
    required String accessKey,
    required String secretKey,
    required String bucketName,
    String? sessionToken,
    String? endpoint,
  }) async {
    try {
      final result = await _channel.invokeMethod('initAWSS3', {
        'region': region,
        'accessKey': accessKey,
        'secretKey': secretKey,
        'bucketName': bucketName,
        'sessionToken': sessionToken,
        'endpoint': endpoint,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('❌ AWS S3 初始化失败: ${e.message}');
      return false;
    }
  }

  /// 上传文件到 AWS S3
  /// [filePath] - 本地文件路径
  /// [objectKey] - 存储对象键（可选，不传则自动生成）
  /// 返回上传结果，包含 url 和 thumbnailUrl
  Future<UploadResult> uploadToAWS({
    required String filePath,
    String? objectKey,
  }) async {
    try {
      final result = await _channel.invokeMethod('uploadToAWS', {
        'filePath': filePath,
        'objectKey': objectKey,
      });
      return UploadResult.fromMap(result as Map<dynamic, dynamic>);
    } on PlatformException catch (e) {
      return UploadResult(success: false, error: e.message);
    }
  }

  // MARK: - 通用方法

  /// 下载文件
  /// [url] - 远程文件 URL
  /// [savePath] - 本地保存路径
  Future<DownloadResult> downloadFile({
    required String url,
    required String savePath,
  }) async {
    try {
      final result = await _channel.invokeMethod('downloadFile', {
        'url': url,
        'savePath': savePath,
      });
      final map = result as Map<dynamic, dynamic>;
      return DownloadResult(
        success: map['success'] == true,
        path: map['path'] as String?,
      );
    } on PlatformException catch (e) {
      return DownloadResult(success: false, error: e.message);
    }
  }

  /// 根据云存储类型上传文件
  /// [type] - 云存储类型: aliyun, tencent, aws
  /// [filePath] - 本地文件路径
  /// [objectKey] - 存储对象键（可选）
  Future<UploadResult> upload({
    required CloudStorageType type,
    required String filePath,
    String? objectKey,
  }) async {
    switch (type) {
      case CloudStorageType.aliyun:
        return uploadToAliyun(filePath: filePath, objectKey: objectKey);
      case CloudStorageType.tencent:
        return uploadToTencent(filePath: filePath, objectKey: objectKey);
      case CloudStorageType.aws:
        return uploadToAWS(filePath: filePath, objectKey: objectKey);
    }
  }
}

/// 云存储类型
enum CloudStorageType {
  aliyun,
  tencent,
  aws,
}

/// 上传结果
class UploadResult {
  final bool success;
  final String? url;
  final String? thumbnailUrl;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.thumbnailUrl,
    this.error,
  });

  factory UploadResult.fromMap(Map<dynamic, dynamic> map) {
    return UploadResult(
      success: map['success'] == true,
      url: map['url'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      error: map['error'] as String?,
    );
  }

  @override
  String toString() {
    return 'UploadResult(success: $success, url: $url, thumbnailUrl: $thumbnailUrl, error: $error)';
  }
}

/// 下载结果
class DownloadResult {
  final bool success;
  final String? path;
  final String? error;

  DownloadResult({
    required this.success,
    this.path,
    this.error,
  });

  @override
  String toString() {
    return 'DownloadResult(success: $success, path: $path, error: $error)';
  }
}

