import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import '../services/native_bridge.dart';
import '../services/message_database.dart';
import 'dart:convert';

class ChatController extends GetxController { 

  static ChatController get to => Get.put(ChatController());

  //  当前会话ID
  String conversationId = '';

  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();

   // 常用表情列表
  List<String> emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '🥲',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😌',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🤧',
    '🥵',
    '🥶',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '🥸',
    '😎',
    '🤓',
    '🧐',
    '😕',
    '😟',
    '🙁',
    '☹️',
    '😮',
    '😯',
    '😲',
    '😳',
    '🥺',
    '😦',
    '😧',
    '😨',
    '😰',
    '😥',
    '😢',
    '😭',
    '😱',
    '😖',
    '😣',
    '😞',
    '😓',
    '😩',
    '😫',
    '🥱',
    '😤',
    '😡',
    '😠',
    '🤬',
    '😈',
    '👿',
    '💀',
    '☠️',
    '💩',
    '👍',
    '👎',
    '👏',
    '🙌',
    '👐',
    '🤲',
    '🤝',
    '🙏',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '👋',
    '🤚',
    '🖐️',
    '✋',
    '🖖',
    '👌',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '💔',
    '❣️',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '🔥',
    '✨',
    '🎉',
    '🎊',
    '🎁',
    '🎈',
  ];


  Future<bool> deleteMessage(String messageId, String conversationId) async {
    final res = await _nativeService.imDeleteMessage(messageId: messageId, conversationId: conversationId);
    if (res['errorCode'] == 0) {
      return true;
    } else {
      return false;
    }
  }

  /// 获取会话列表（带用户头像）
  /// 从数据库获取对方的头像信息并合并到会话列表中
  Future<List<Map<String, dynamic>>> getConversationList({
    int page = 1,
    int pageSize = 20,
    int convType = 0,
    bool isUnread = false,
    bool isAtMe = false,
  }) async {
    try {
      // 1. 请求会话列表
      final result = await _nativeService.imGetConversationList(
        page: page,
        pageSize: pageSize,
        convType: convType,
        isUnread: isUnread,
        isAtMe: isAtMe,
      );

      if (result['errorCode'] != 0) {
        return [];
      }

      // 2. 解析返回的数据
      final data = result['data'];
      if (data == null || (data is String && data.isEmpty)) {
        return [];
      }

      String dataStr = '';
      if (data is String) {
        dataStr = data;
      } else if (data is Map) {
        dataStr = json.encode(data);
      } else {
        return [];
      }

      final dataMap = json.decode(dataStr) as Map<String, dynamic>;
      final conversations = (dataMap['conversations'] as List?) ?? [];

      if (conversations.isEmpty) {
        return [];
      }

      // 3. 提取所有单聊会话的 targetId（对方用户ID）
      final targetIds = <String>{};
      for (final conv in conversations) {
        if (conv is Map) {
          final convTypeValue = conv['conv_type'] as int? ?? 0;
          final targetId = conv['target_id'] as String?;
          // 只处理单聊（convType = 0）且有 targetId 的情况
          if (convTypeValue == 1 && targetId != null && targetId.isNotEmpty) {
            targetIds.add(targetId);
          }
        }
      }

      // 4. 从数据库批量获取用户信息（头像、昵称）
      final usersFromDb = <String, Map<String, dynamic>>{};
      if (targetIds.isNotEmpty) {
        final users = await _messageDatabase.getUsers(targetIds.toList());
        for (final user in users) {
          final userId = user['user_id'] as String?;
          if (userId != null) {
            usersFromDb[userId] = user;
          }
        }
      }

      // 5. 合并会话数据和数据库中的用户信息
      final enrichedConversations = conversations.map((conv) {
        if (conv is! Map) return conv;
        final conversation = Map<String, dynamic>.from(conv.cast<String, dynamic>());
        final convTypeValue = conversation['conv_type'] as int? ?? 0;
        final targetId = conversation['target_id'] as String?;

        // 只处理单聊会话
        if (convTypeValue == 1 && targetId != null && usersFromDb.containsKey(targetId)) {
          final userInfo = usersFromDb[targetId]!;
          // 如果会话中没有头像或头像为空，使用数据库中的头像
          final currentAvatar = conversation['avatar'] as String?;
          if ((currentAvatar == null || currentAvatar.isEmpty) && 
              userInfo['avatar'] != null && 
              (userInfo['avatar'] as String).isNotEmpty) {
            conversation['avatar'] = userInfo['avatar'];
            conversation['avatar_url'] = userInfo['avatar'];
          }
          // 同时添加 avatar_bg 字段
          if (userInfo['avatar_bg'] != null) {
            conversation['avatar_bg'] = userInfo['avatar_bg'];
          }
        }

        return conversation;
      }).toList();

      return enrichedConversations.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e) {
      print('获取会话列表失败: $e');
      return [];
    }
  }



  /// 压缩图片，返回压缩后的路径（失败则返回 null）。
  /// 规则：仅对大于1MB的文件压缩，目标不超过1MB，分层次降低质量。
  Future<String?> compressImage(String sourcePath) async {
    const int oneMB = 1024 * 1024;
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return null;
      final srcSize = await srcFile.length();
      if (srcSize <= oneMB) {
        // 小于等于1MB无需压缩
        return null;
      }

      final targetDir = await getTemporaryDirectory();
      final baseName = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
      final tryQualities = [80, 70, 60, 50, 40, 30];

      for (final q in tryQualities) {
        final targetPath = '${targetDir.path}/$baseName\_q$q.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          targetPath,
          quality: q,
          minWidth: 1280,
          minHeight: 1280,
        );
        if (result != null && File(result.path).existsSync()) {
          final newSize = await File(result.path).length();
          print('✅ 图片压缩: q=$q size=${newSize / 1024}KB path=${result.path}');
          if (newSize <= oneMB) {
            return result.path;
          } else {
            // 继续尝试更低质量
            continue;
          }
        }
      }

      // 最低质量后仍大于1MB，则使用最后结果（已尽力）
      final fallbackPath = '${targetDir.path}/$baseName\_fallback.jpg';
      final fallback = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        fallbackPath,
        quality: 20,
        minWidth: 1280,
        minHeight: 1280,
      );
      if (fallback != null && File(fallback.path).existsSync()) {
        print('⚠️ 图片压缩未达1MB，使用最低质量结果: ${fallback.path}');
        return fallback.path;
      }

      print('⚠️ 图片压缩失败，使用原图');
      return null;
    } catch (e) {
      print('⚠️ 图片压缩异常，使用原图: $e');
      return null;
    }
  }



  /// 压缩视频，返回压缩后的路径（失败则返回 null）
  Future<String?> compressVideo(String sourcePath) async {
    try {
      print('🎬 开始压缩视频: $sourcePath');
      EasyLoading.show(status: '正在压缩视频...');

      // 压缩视频
      final mediaInfo = await VideoCompress.compressVideo(
        sourcePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo != null &&
          mediaInfo.path != null &&
          File(mediaInfo.path!).existsSync()) {
        final originalSize = await File(sourcePath).length();
        final compressedSize =
            mediaInfo.filesize ?? await File(mediaInfo.path!).length();
        final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
        print(
          '✅ 视频压缩成功: ${originalSize / 1024 / 1024}MB -> ${compressedSize / 1024 / 1024}MB (${ratio}%)',
        );
        EasyLoading.dismiss();
        return mediaInfo.path;
      } else {
        print('⚠️ 视频压缩失败: 返回路径为空或文件不存在');
        EasyLoading.dismiss();
        return null;
      }
    } catch (e) {
      print('⚠️ 视频压缩失败: $e');
      EasyLoading.dismiss();
      return null;
    }
  }

}