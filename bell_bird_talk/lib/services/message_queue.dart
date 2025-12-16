import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import 'message_database.dart';
import 'native_bridge.dart';
import 'file_path_helper.dart';

/// 消息发送任务
class MessageTask {
  final ChatMessage message;
  final Completer<bool> completer;
  bool isProcessing;

  MessageTask({
    required this.message,
    required this.completer,
    this.isProcessing = false,
  });
}

/// 消息发送状态回调
typedef MessageStatusCallback = void Function(ChatMessage message);

/// 消息发送队列管理器
class MessageQueueManager {
  static final MessageQueueManager _instance = MessageQueueManager._internal();
  factory MessageQueueManager() => _instance;
  MessageQueueManager._internal();

  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _database = MessageDatabase();
  
  /// 发送队列（按会话ID分组）
  final Map<String, List<MessageTask>> _queues = {};
  
  /// 最大并发发送数
  static const int _maxConcurrent = 3;
  
  /// 当前正在发送的任务数
  final Map<String, int> _sendingCount = {};
  
  /// 消息状态变化回调
  final List<MessageStatusCallback> _statusCallbacks = [];
  
  /// 添加状态变化监听
  void addStatusListener(MessageStatusCallback callback) {
    _statusCallbacks.add(callback);
  }
  
  /// 移除状态变化监听
  void removeStatusListener(MessageStatusCallback callback) {
    _statusCallbacks.remove(callback);
  }
  
  /// 通知状态变化
  void _notifyStatusChange(ChatMessage message) {
    for (final callback in _statusCallbacks) {
      callback(message);
    }
  }

  /// 发送消息（加入队列）
  Future<bool> sendMessage(ChatMessage message) async {
    final completer = Completer<bool>();
    final task = MessageTask(message: message, completer: completer);
    print("sendMessage: ${message.toDbMap()}");
    // 保存到数据库
    await _database.insertMessage(message);
    
    // 加入队列
    _queues.putIfAbsent(message.convId, () => []);
    _queues[message.convId]!.add(task);
    
    // 通知状态变化
    _notifyStatusChange(message);
    
    // 处理队列
    _processQueue(message.convId);
    
    return completer.future;
  }

  /// 重新发送失败的消息
  Future<bool> resendMessage(String localId) async {
    // 从数据库获取消息
    final messages = await _database.getPendingMessages();
    final message = messages.firstWhere(
      (m) => m.localId == localId,
      orElse: () => throw Exception('Message not found'),
    );
    
    // 更新状态为等待发送
    message.status = MessageStatus.pending;
    message.retryCount = message.retryCount + 1;
    await _database.updateMessage(message);
    
    // 重新发送
    return sendMessage(message);
  }

  /// 处理发送队列
  void _processQueue(String convId) async {
    final queue = _queues[convId];
    if (queue == null || queue.isEmpty) return;
    
    _sendingCount.putIfAbsent(convId, () => 0);
    
    // 检查并发数
    while (_sendingCount[convId]! < _maxConcurrent && queue.isNotEmpty) {
      // 找到第一个未处理的任务
      final taskIndex = queue.indexWhere((t) => !t.isProcessing);
      if (taskIndex == -1) break;
      
      final task = queue[taskIndex];
      task.isProcessing = true;
      _sendingCount[convId] = _sendingCount[convId]! + 1;
      
      // 异步发送（不等待，允许并发）
      _sendMessageTask(task).then((success) {
        // 从队列移除
        queue.remove(task);
        _sendingCount[convId] = _sendingCount[convId]! - 1;
        
        // 继续处理队列
        _processQueue(convId);
      });
    }
  }

  /// 执行消息发送任务
  Future<bool> _sendMessageTask(MessageTask task) async {
    final message = task.message;
    
    try {
      // 更新状态为发送中
      message.status = MessageStatus.sending;
      await _database.updateMessageStatus(message.localId, MessageStatus.sending);
      _notifyStatusChange(message);
      
      bool success = false;
      
      switch (message.type) {
        case MessageType.text:
          success = await _sendTextMessage(message);
          break;
        case MessageType.image:
          success = await _sendImageMessage(message);
          break;
        case MessageType.voice:
          success = await _sendVoiceMessage(message);
          break;
        // 其他类型暂时不支持
        default:
          success = false;
          message.errorMessage = '暂不支持该消息类型';
      }
      
      if (success) {
        message.status = MessageStatus.sent;
        message.sentAt = DateTime.now().millisecondsSinceEpoch;
        await _database.updateMessageStatus(message.localId, MessageStatus.sent);
      } else {
        message.status = MessageStatus.failed;
        await _database.updateMessageStatus(
          message.localId, 
          MessageStatus.failed,
          errorMessage: message.errorMessage,
        );
      }
      
      _notifyStatusChange(message);
      task.completer.complete(success);
      return success;
      
    } catch (e) {
      print('❌ 发送消息异常: $e');
      message.status = MessageStatus.failed;
      message.errorMessage = e.toString();
      await _database.updateMessageStatus(
        message.localId, 
        MessageStatus.failed,
        errorMessage: e.toString(),
      );
      _notifyStatusChange(message);
      task.completer.complete(false);
      return false;
    }
  }

  /// 发送文本消息
  Future<bool> _sendTextMessage(ChatMessage message) async {
    final result = await _nativeService.imSendTextMessage(
      content: message.textContent ?? '',
      conversationId: message.convId,
      receiverId: message.receiverId,
    );
    
    if (result['errorCode'] == 0) {
      // 更新服务器消息ID
      if (result['data'] != null) {
        try {
          final data = result['data'] is String 
              ? json.decode(result['data']) 
              : result['data'];
          if (data is Map && data['msg_id'] != null) {
            message.serverId = data['msg_id'].toString();
            await _database.updateMessageServerId(message.localId, message.serverId!);
          }
        } catch (e) {
          print('解析消息ID失败: $e');
        }
      }
      return true;
    } else {
      message.errorMessage = result['message'] ?? '发送失败';
      return false;
    }
  }

  /// 发送图片消息
  Future<bool> _sendImageMessage(ChatMessage message) async {
    final localPath = message.imageLocalPath;
    if (localPath == null || localPath.isEmpty) {
      message.errorMessage = '图片路径为空';
      return false;
    }
    
    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullPath = await pathHelper.toFullPath(localPath);
    
    final file = File(fullPath);
    if (!await file.exists()) {
      print('图片文件不存在: $fullPath');
      message.errorMessage = '图片文件不存在';
      return false;
    }
    
    try {
      // 1. 获取上传凭证
      final fileName = fullPath.split('/').last;
      final fileSize = await file.length();
      final contentType = lookupMimeType(fullPath) ?? 'image/jpeg';
      
      print('📤 准备上传图片: $fileName, $fileSize bytes, $contentType');
      
      final prepareResult = await _nativeService.imPrepareUpload(
        businessModule: 'message',
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
      
      if (prepareResult['errorCode'] != 0) {
        message.errorMessage = prepareResult['message'] ?? '获取上传凭证失败';
        return false;
      }
      
      // 2. 解析上传凭证
      final tokenDataStr = prepareResult['data'] as String?;
      if (tokenDataStr == null || tokenDataStr.isEmpty) {
        message.errorMessage = '上传凭证数据为空';
        return false;
      }
      
      final tokenData = json.decode(tokenDataStr) as Map<String, dynamic>;
      final uploadUrl = tokenData['upload_url'] as String? ?? '';
      final method = tokenData['method'] as String? ?? '';
      final fileUrl = tokenData['file_url'] as String? ?? '';
      final uploadMode = tokenData['upload_mode'] as String? ?? '';
      final providerCode = tokenData['provider_code'] as String? ?? '';
      
      // STS 凭证
      final objectKey = tokenData['file_path'] as String? ?? '';
      final bucketName = tokenData['bucket_name'] as String? ?? '';
      final region = tokenData['region'] as String? ?? '';
      final stsAccessKeyId = tokenData['sts_access_key_id'] as String? ?? '';
      final stsAccessKeySecret = tokenData['sts_access_key_secret'] as String? ?? '';
      final stsSecurityToken = tokenData['sts_security_token'] as String? ?? '';
      
      print('📤 上传模式: $uploadMode, 提供商: $providerCode');
      
      // 3. 执行上传
      bool uploadSuccess = false;
      
      if (uploadMode == 'STS_SDK' && providerCode == 'tencent') {
        // 腾讯云 STS SDK 上传
        uploadSuccess = await _uploadWithTencentSTS(
          localFilePath: fullPath,
          objectKey: objectKey,
          bucketName: bucketName,
          region: region,
          secretId: stsAccessKeyId,
          secretKey: stsAccessKeySecret,
          token: stsSecurityToken,
        );
      } else if (uploadUrl.isNotEmpty) {
        // HTTP 上传（PUT 或 POST）
        if (method.toUpperCase() == 'PUT') {
          uploadSuccess = await _uploadWithPut(uploadUrl, file, tokenData['headers'] as Map<String, dynamic>?);
        } else if (method.toUpperCase() == 'POST') {
          uploadSuccess = await _uploadWithPost(
            uploadUrl, 
            file, 
            tokenData['file_path'] as String?,
            tokenData['headers'] as Map<String, dynamic>?,
            tokenData['form_data'] as Map<String, dynamic>?,
          );
        } else {
          message.errorMessage = '不支持的上传方法: $method';
          return false;
        }
      } else {
        message.errorMessage = '不支持的上传模式: $uploadMode';
        return false;
      }
      
      if (!uploadSuccess) {
        message.errorMessage = '文件上传失败';
        return false;
      }
      
      // 4. 更新图片URL
      message.imageUrl = fileUrl;
      await _database.updateImageUrl(message.localId, fileUrl, null);
      
      print('✅ 图片上传成功: $fileUrl');
      
      // 5. 发送图片消息到服务器
      print('📤 开始发送图片消息到服务器...');
      final sendResult = await _nativeService.imSendImageMessage(
        imageUrl: fileUrl,
        conversationId: message.convId,
        receiverId: message.receiverId,
        thumbnailUrl: message.imageThumbnailUrl,
        width: message.imageWidth,
        height: message.imageHeight,
      );
      
      if (sendResult['errorCode'] == 0) {
        // 更新服务器消息ID
        if (sendResult['data'] != null) {
          try {
            final data = sendResult['data'] is String 
                ? json.decode(sendResult['data']) 
                : sendResult['data'];
            if (data is Map && data['msg_id'] != null) {
              message.serverId = data['msg_id'].toString();
              await _database.updateMessageServerId(message.localId, message.serverId!);
            }
          } catch (e) {
            print('解析图片消息ID失败: $e');
          }
        }
        print('✅ 图片消息发送成功');
      return true;
      } else {
        message.errorMessage = sendResult['message'] ?? '发送图片消息失败';
        print('❌ 图片消息发送失败: ${message.errorMessage}');
        return false;
      }
      
    } catch (e) {
      print('❌ 图片上传异常: $e');
      message.errorMessage = '上传异常: $e';
      return false;
    }
  }

  /// 发送语音消息
  Future<bool> _sendVoiceMessage(ChatMessage message) async {
    final localPath = message.fileLocalPath;
    if (localPath == null || localPath.isEmpty) {
      message.errorMessage = '语音文件路径为空';
      return false;
    }
    
    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullPath = await pathHelper.toFullPath(localPath);
    
    final file = File(fullPath);
    if (!await file.exists()) {
      message.errorMessage = '语音文件不存在';
      return false;
    }
    
    try {
      // 1. 获取上传凭证
      final fileName = fullPath.split('/').last;
      final fileSize = await file.length();
      final contentType = lookupMimeType(fullPath) ?? 'audio/m4a';
      
      print('📤 准备上传语音: $fileName, $fileSize bytes, $contentType, 时长: ${message.voiceDuration}s');
      
      final prepareResult = await _nativeService.imPrepareUpload(
        businessModule: 'message',
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
      
      if (prepareResult['errorCode'] != 0) {
        message.errorMessage = prepareResult['message'] ?? '获取上传凭证失败';
        return false;
      }
      
      // 2. 解析上传凭证
      final tokenDataStr = prepareResult['data'] as String?;
      if (tokenDataStr == null || tokenDataStr.isEmpty) {
        message.errorMessage = '上传凭证数据为空';
        return false;
      }
      
      final tokenData = json.decode(tokenDataStr) as Map<String, dynamic>;
      final uploadUrl = tokenData['upload_url'] as String? ?? '';
      final method = tokenData['method'] as String? ?? '';
      final fileUrl = tokenData['file_url'] as String? ?? '';
      final uploadMode = tokenData['upload_mode'] as String? ?? '';
      final providerCode = tokenData['provider_code'] as String? ?? '';
      
      // STS 凭证
      final voiceObjectKey = tokenData['file_path'] as String? ?? '';
      final voiceBucketName = tokenData['bucket_name'] as String? ?? '';
      final voiceRegion = tokenData['region'] as String? ?? '';
      final voiceStsAccessKeyId = tokenData['sts_access_key_id'] as String? ?? '';
      final voiceStsAccessKeySecret = tokenData['sts_access_key_secret'] as String? ?? '';
      final voiceStsSecurityToken = tokenData['sts_security_token'] as String? ?? '';
      
      print('📤 语音上传模式: $uploadMode, 提供商: $providerCode');
      
      // 3. 执行上传
      bool uploadSuccess = false;
      
      if (uploadMode == 'STS_SDK' && providerCode == 'tencent') {
        // 腾讯云 STS SDK 上传
        uploadSuccess = await _uploadWithTencentSTS(
          localFilePath: fullPath,
          objectKey: voiceObjectKey,
          bucketName: voiceBucketName,
          region: voiceRegion,
          secretId: voiceStsAccessKeyId,
          secretKey: voiceStsAccessKeySecret,
          token: voiceStsSecurityToken,
        );
      } else if (uploadUrl.isNotEmpty) {
        // HTTP 上传
        if (method.toUpperCase() == 'PUT') {
          uploadSuccess = await _uploadWithPut(uploadUrl, file, tokenData['headers'] as Map<String, dynamic>?);
        } else if (method.toUpperCase() == 'POST') {
          uploadSuccess = await _uploadWithPost(
            uploadUrl, 
            file, 
            tokenData['file_path'] as String?,
            tokenData['headers'] as Map<String, dynamic>?,
            tokenData['form_data'] as Map<String, dynamic>?,
          );
        } else {
          message.errorMessage = '不支持的上传方法: $method';
          return false;
        }
      } else {
        message.errorMessage = '不支持的上传模式: $uploadMode';
        return false;
      }
      
      if (!uploadSuccess) {
        message.errorMessage = '语音文件上传失败';
        return false;
      }
      
      // 4. 更新语音URL
      message.fileUrl = fileUrl;
      await _database.updateVoiceUrl(message.localId, fileUrl);
      
      print('✅ 语音上传成功: $fileUrl');
      
      // 5. 发送语音消息到服务器
      print('📤 开始发送语音消息到服务器...');
      final sendResult = await _nativeService.imSendVoiceMessage(
        audioUrl: fileUrl,
        duration: message.voiceDuration ?? 0,
        conversationId: message.convId,
        receiverId: message.receiverId,
      );
      
      if (sendResult['errorCode'] == 0) {
        // 更新服务器消息ID
        if (sendResult['data'] != null) {
          try {
            final data = sendResult['data'] is String 
                ? json.decode(sendResult['data']) 
                : sendResult['data'];
            if (data is Map && data['msg_id'] != null) {
              message.serverId = data['msg_id'].toString();
              await _database.updateMessageServerId(message.localId, message.serverId!);
            }
          } catch (e) {
            print('解析语音消息ID失败: $e');
          }
        }
        print('✅ 语音消息发送成功');
      return true;
      } else {
        message.errorMessage = sendResult['message'] ?? '发送语音消息失败';
        print('❌ 语音消息发送失败: ${message.errorMessage}');
        return false;
      }
      
    } catch (e) {
      print('❌ 语音上传异常: $e');
      message.errorMessage = '上传异常: $e';
      return false;
    }
  }

  /// PUT 方式上传
  Future<bool> _uploadWithPut(String url, File file, Map<String, dynamic>? headers) async {
    final client = http.Client();
    try {
      final request = http.Request('PUT', Uri.parse(url));
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers[key] = value.toString();
        });
      }
      request.bodyBytes = await file.readAsBytes();
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();
      print('PUT upload response: ${response.statusCode}, body: $responseBody');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('PUT upload error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  /// POST 方式上传（表单）
  Future<bool> _uploadWithPost(
    String url, 
    File file, 
    String? filePath,
    Map<String, dynamic>? headers, 
    Map<String, dynamic>? formData,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers[key] = value.toString();
        });
      }
      
      if (formData != null) {
        formData.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }
      
      final fileName = file.path.split('/').last;
      request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: fileName));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('POST upload response: ${response.statusCode}, body: $responseBody');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('POST upload error: $e');
      return false;
    }
  }
  
  /// 腾讯云 STS SDK 上传
  Future<bool> _uploadWithTencentSTS({
    required String localFilePath,
    required String objectKey,
    required String bucketName,
    required String region,
    required String secretId,
    required String secretKey,
    required String token,
  }) async {
    try {
      final result = await _nativeService.imUploadWithTencentSTS(
        localFilePath: localFilePath,
        objectKey: objectKey,
        bucketName: bucketName,
        region: region,
        secretId: secretId,
        secretKey: secretKey,
        token: token,
      );
      
      final success = result['success'] as bool? ?? false;
      if (!success) {
        print('❌ 腾讯云 STS 上传失败: ${result['error']}');
      }
      return success;
    } catch (e) {
      print('❌ 腾讯云 STS 上传异常: $e');
      return false;
    }
  }

  /// 取消发送
  void cancelMessage(String localId) {
    for (final queue in _queues.values) {
      final taskIndex = queue.indexWhere((t) => t.message.localId == localId && !t.isProcessing);
      if (taskIndex != -1) {
        final task = queue.removeAt(taskIndex);
        task.completer.complete(false);
        break;
      }
    }
  }

  /// 获取队列中的消息数量
  int getQueueCount(String convId) {
    return _queues[convId]?.length ?? 0;
  }

  /// 清空队列
  void clearQueue(String convId) {
    final queue = _queues[convId];
    if (queue != null) {
      for (final task in queue.where((t) => !t.isProcessing)) {
        task.completer.complete(false);
      }
      queue.removeWhere((t) => !t.isProcessing);
    }
  }
}

