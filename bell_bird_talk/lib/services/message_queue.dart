import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../models/chat_message.dart';
import '../controllers/global_controller.dart';
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
  
  /// 获取当前用户ID
  Future<String> _getCurrentUserId() async {
    try {
      final controller = Get.find<GlobalController>();
      final userId = controller.currentUser.value?.id;
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    } catch (e) {
      print('获取当前用户ID失败: $e');
    }
    return '';
  }

  /// 发送消息（加入队列）
  Future<bool> sendMessage(ChatMessage message) async {

    // 保存到数据库
    ChatMessage msg = await _database.insertMessage(message);
    print("发送后插入消息到数据库: $msg ${msg.localId}");
    message.ext = msg.localId;
    final completer = Completer<bool>();
    final task = MessageTask(message: message, completer: completer);
    print("sendMessage: ${message.toDbMap()}");
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
      
      // 查询会话类型（判断是单聊还是群聊）
      final userId = await _getCurrentUserId();
      final conversation = await _database.getConversation(userId, message.convId);
      final convType = conversation?.convType ?? 0;
      final isGroupChat = convType == 2;
      
      bool success = false;
      
      switch (message.type) {
        case MessageType.text:
          success = isGroupChat 
              ? await _sendGroupTextMessage(message)
              : await _sendTextMessage(message);
          break;
        case MessageType.image:
          success = isGroupChat
              ? await _sendGroupImageMessage(message)
              : await _sendImageMessage(message);
          break;
        case MessageType.voice:
          success = isGroupChat
              ? await _sendGroupVoiceMessage(message)
              : await _sendVoiceMessage(message);
          break;
        case MessageType.video:
          success = await _sendVideoMessage(message);
          break;
           case MessageType.at:
          success = await _sendAtMessage(message);
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
      ext: message.ext,
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
  
  /// 发送群聊AT消息
  Future<bool> _sendAtMessage(ChatMessage message) async {
    final result = await _nativeService.imSendGroupAtMessage(content: message.textContent ?? '', conversationId: message.convId, groupId: message.receiverId, atInfoList: message.atInfoList ?? []);
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
          print('解析群聊消息ID失败: $e');
        }
      }
      return true;
    } else {
      message.errorMessage = result['message'] ?? '发送失败';
      return false;
    }
  }

  /// 发送群聊文本消息
  Future<bool> _sendGroupTextMessage(ChatMessage message) async {
    final result = await _nativeService.imSendGroupTextMessage(
      content: message.textContent ?? '',
      conversationId: message.convId,
      groupId: message.receiverId,
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
          print('解析群聊消息ID失败: $e');
        }
      }
      return true;
    } else {
      message.errorMessage = result['message'] ?? '发送失败';
      return false;
    }
  }
  
  /// 发送群聊图片消息
  Future<bool> _sendGroupImageMessage(ChatMessage message) async {
    // 群聊图片消息的上传逻辑与单聊相同，只是发送接口不同
    // 这里复用单聊的上传逻辑，然后在发送时调用群聊接口
    return await _sendImageMessage(message);
  }
  
  /// 发送群聊语音消息
  Future<bool> _sendGroupVoiceMessage(ChatMessage message) async {
    // 群聊语音消息的上传逻辑与单聊相同，只是发送接口不同
    // 这里复用单聊的上传逻辑，然后在发送时调用群聊接口
    return await _sendVoiceMessage(message);
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
    final coverLocalPath = message.imageLocalPath;
    
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
      String? coverUrl;
      // 3.1 先上传封面（如果有）
      if (coverLocalPath != null) {
        final coverFull = await pathHelper.toFullPath(coverLocalPath);
        final coverFile = File(coverFull);
        if (!await coverFile.exists()) {
          print('⚠️ 视频封面不存在，跳过封面上传');
        } else {
          final coverName = coverFull.split('/').last;
          final coverSize = await coverFile.length();
          final coverContentType = lookupMimeType(coverFull) ?? 'image/png';

          final coverPrepare = await _nativeService.imPrepareUpload(
            businessModule: 'message',
            fileName: coverName,
            fileSize: coverSize,
            contentType: coverContentType,
          );
          if (coverPrepare['errorCode'] == 0) {
            final coverDataStr = coverPrepare['data'] as String?;
            if (coverDataStr != null && coverDataStr.isNotEmpty) {
              final coverToken = json.decode(coverDataStr) as Map<String, dynamic>;
              final coverUploadUrl = coverToken['upload_url'] as String? ?? '';
              final coverMethod = coverToken['method'] as String? ?? '';
              final coverUploadMode = coverToken['upload_mode'] as String? ?? '';
              final coverProvider = coverToken['provider_code'] as String? ?? '';

              bool coverOk = false;
              if (coverUploadMode == 'STS_SDK' && coverProvider == 'tencent') {
                coverOk = await _uploadWithTencentSTS(
                  localFilePath: coverFull,
                  objectKey: coverToken['file_path'] as String? ?? '',
                  bucketName: coverToken['bucket_name'] as String? ?? '',
                  region: coverToken['region'] as String? ?? '',
                  secretId: coverToken['sts_access_key_id'] as String? ?? '',
                  secretKey: coverToken['sts_access_key_secret'] as String? ?? '',
                  token: coverToken['sts_security_token'] as String? ?? '',
                );
              } else if (coverUploadUrl.isNotEmpty) {
                if (coverMethod.toUpperCase() == 'PUT') {
                  coverOk = await _uploadWithPut(
                    coverUploadUrl,
                    coverFile,
                    coverToken['headers'] as Map<String, dynamic>?,
                  );
                } else if (coverMethod.toUpperCase() == 'POST') {
                  coverOk = await _uploadWithPost(
                    coverUploadUrl,
                    coverFile,
                    coverToken['file_path'] as String?,
                    coverToken['headers'] as Map<String, dynamic>?,
                    coverToken['form_data'] as Map<String, dynamic>?,
                  );
                }
              }

              if (coverOk) {
                coverUrl = coverToken['file_url'] as String? ?? '';
                message.imageUrl = coverUrl;
                await _database.updateImageUrl(message.localId, coverUrl, null);
                print('✅ 封面上传成功: $coverUrl');
              } else {
                print('⚠️ 封面上传失败，但继续上传视频主体');
              }
            }
          }
        }
      }
      
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
      
      // 5. 发送图片消息到服务器（根据会话类型选择方法）
      print('📤 开始发送图片消息到服务器...');
      final userId = await _getCurrentUserId();
      final conversation = await _database.getConversation(userId, message.convId);
      final convType = conversation?.convType ?? 0;
      final isGroupChat = convType == 2;
      
      final sendResult = isGroupChat
          ? await _nativeService.imSendGroupImageMessage(
              imageUrl: fileUrl,
              conversationId: message.convId,
              groupId: message.receiverId,
              thumbnailUrl: message.imageThumbnailUrl,
              width: message.imageWidth,
              height: message.imageHeight,
            )
          : await _nativeService.imSendImageMessage(
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
      
      // 3.2 上传视频主体
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
      
      // 5. 发送语音消息到服务器（根据会话类型选择方法）
      print('📤 开始发送语音消息到服务器...');
      final userId = await _getCurrentUserId();
      final conversation = await _database.getConversation(userId, message.convId);
      final convType = conversation?.convType ?? 0;
      final isGroupChat = convType == 2;
      
      final sendResult = isGroupChat
          ? await _nativeService.imSendGroupVoiceMessage(
              audioUrl: fileUrl,
              duration: message.voiceDuration ?? 0,
              conversationId: message.convId,
              groupId: message.receiverId,
            )
          : await _nativeService.imSendVoiceMessage(
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

  /// 发送视频消息
  Future<bool> _sendVideoMessage(ChatMessage message) async {
    final localPath = message.fileLocalPath;
    if (localPath == null || localPath.isEmpty) {
      message.errorMessage = '视频文件路径为空';
      return false;
    }

    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullPath = await pathHelper.toFullPath(localPath);
    final coverLocalPath = message.imageLocalPath;

    final file = File(fullPath);
    if (!await file.exists()) {
      message.errorMessage = '视频文件不存在';
      return false;
    }

    try {
      // 1. 获取上传凭证
      final fileName = fullPath.split('/').last;
      final fileSize = await file.length();
      final contentType = lookupMimeType(fullPath) ?? 'video/mp4';

      print('📤 准备上传视频: $fileName, $fileSize bytes, $contentType');

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
      String? coverUrl;
      // 3.1 上传封面（如有）
      if (coverLocalPath != null && coverLocalPath.isNotEmpty) {
        final coverFull = await pathHelper.toFullPath(coverLocalPath);
        final coverFile = File(coverFull);
        if (await coverFile.exists()) {
          final coverName = coverFull.split('/').last;
          final coverSize = await coverFile.length();
          final coverContentType = lookupMimeType(coverFull) ?? 'image/png';

          final coverPrepare = await _nativeService.imPrepareUpload(
            businessModule: 'message',
            fileName: coverName,
            fileSize: coverSize,
            contentType: coverContentType,
          );

          if (coverPrepare['errorCode'] == 0) {
            final coverDataStr = coverPrepare['data'] as String?;
            if (coverDataStr != null && coverDataStr.isNotEmpty) {
              final coverToken = json.decode(coverDataStr) as Map<String, dynamic>;
              final coverUploadUrl = coverToken['upload_url'] as String? ?? '';
              final coverMethod = coverToken['method'] as String? ?? '';
              final coverUploadMode = coverToken['upload_mode'] as String? ?? '';
              final coverProvider = coverToken['provider_code'] as String? ?? '';

              bool coverOk = false;
              if (coverUploadMode == 'STS_SDK' && coverProvider == 'tencent') {
                coverOk = await _uploadWithTencentSTS(
                  localFilePath: coverFull,
                  objectKey: coverToken['file_path'] as String? ?? '',
                  bucketName: coverToken['bucket_name'] as String? ?? '',
                  region: coverToken['region'] as String? ?? '',
                  secretId: coverToken['sts_access_key_id'] as String? ?? '',
                  secretKey: coverToken['sts_access_key_secret'] as String? ?? '',
                  token: coverToken['sts_security_token'] as String? ?? '',
                );
              } else if (coverUploadUrl.isNotEmpty) {
                if (coverMethod.toUpperCase() == 'PUT') {
                  coverOk = await _uploadWithPut(
                    coverUploadUrl,
                    coverFile,
                    coverToken['headers'] as Map<String, dynamic>?,
                  );
                } else if (coverMethod.toUpperCase() == 'POST') {
                  coverOk = await _uploadWithPost(
                    coverUploadUrl,
                    coverFile,
                    coverToken['file_path'] as String?,
                    coverToken['headers'] as Map<String, dynamic>?,
                    coverToken['form_data'] as Map<String, dynamic>?,
                  );
                }
              }

              if (coverOk) {
                coverUrl = coverToken['file_url'] as String? ?? '';
                message.imageUrl = coverUrl;
                await _database.updateImageUrl(message.localId, coverUrl, null);
                print('✅ 封面上传成功: $coverUrl');
              } else {
                print('⚠️ 封面上传失败，但继续上传视频主体');
              }
            }
          }
        }
      }

      // 3.2 上传视频主体
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
          uploadSuccess = await _uploadWithPut(
            uploadUrl,
            file,
            tokenData['headers'] as Map<String, dynamic>?,
          );
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

      // 4. 更新视频URL
      message.fileUrl = fileUrl;
      await _database.updateVoiceUrl(message.localId, fileUrl);

      print('✅ 视频上传成功: $fileUrl');

      // 5. 发送视频消息到服务器
      print('📤 开始发送视频消息到服务器...');
      
      // 判断是群组消息还是单聊消息
      final userId = await _getCurrentUserId();
      final conversation = await _database.getConversation(userId, message.convId);
      final convType = conversation?.convType ?? 0;
      final isGroupChat = convType == 2;
      
      final sendResult = isGroupChat
          ? await _nativeService.imSendGroupVideoMessage(
              videoUrl: fileUrl,
              coverUrl: coverUrl,
              conversationId: message.convId,
              groupId: message.receiverId,
              duration: message.videoDuration,
              width: message.imageWidth,
              height: message.imageHeight,
              size: fileSize,
            )
          : await _nativeService.imSendVideoMessage(
              videoUrl: fileUrl,
              coverUrl: coverUrl,
              conversationId: message.convId,
              receiverId: message.receiverId,
              duration: message.videoDuration,
              width: message.imageWidth,
              height: message.imageHeight,
              size: fileSize,
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
              await _database.updateMessageServerId(
                  message.localId, message.serverId!);
            }
          } catch (e) {
            print('解析视频消息ID失败: $e');
          }
        }
        print('✅ 视频消息发送成功');
        return true;
      } else {
        message.errorMessage = sendResult['message'] ?? '发送视频消息失败';
        print('❌ 视频消息发送失败: ${message.errorMessage}');
        return false;
      }
    } catch (e) {
      print('❌ 视频上传异常: $e');
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

