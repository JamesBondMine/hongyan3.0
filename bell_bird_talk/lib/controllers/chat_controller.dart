import 'package:get/get.dart';
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
}