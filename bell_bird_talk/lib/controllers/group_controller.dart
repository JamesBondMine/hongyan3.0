import 'dart:convert';
import 'package:get/get.dart';
import '../services/native_bridge.dart';
import '../services/message_database.dart';

class GroupController extends GetxController { 

  static GroupController get to => Get.put(GroupController());

  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();

  // 缓存：key 为缓存键，value 为 { 'data': Map, 'timestamp': int }
  final Map<String, Map<String, dynamic>> _membersCache = {};
  static const int _cacheDuration = 60 * 1000; // 1分钟（毫秒）

  /// 生成缓存键
  String _getCacheKey(String groupId, int status, int page, int pageSize) {
    return '${groupId}_${status}_${page}_${pageSize}';
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String cacheKey) {
    if (!_membersCache.containsKey(cacheKey)) {
      return false;
    }
    final cache = _membersCache[cacheKey];
    final timestamp = cache?['timestamp'] as int?;
    if (timestamp == null) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) < _cacheDuration;
  }

  /// 获取群成员列表
  /// 返回格式: { 'errorCode': int, 'message': String, 'members': List, 'creatorUserId': String? }
  Future<Map<String, dynamic>> getGroupMembersFullInfo(
    String groupId, {
    int status = 0,
    int page = 1,
    int pageSize = 200,
    bool forceRefresh = false,
  }) async {
    // 检查缓存
    final cacheKey = _getCacheKey(groupId, status, page, pageSize);
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      print('📦 使用缓存的群成员数据: $groupId');
      return _membersCache[cacheKey]!['data'] as Map<String, dynamic>;
    }

    try {
      // 1. 请求群成员数据
      final result = await _nativeService.imGetGroupMembers(
        groupId: groupId,
        status: status,
        page: page,
        pageSize: pageSize,
      );

      if (result['errorCode'] != 0) {
        return {
          'errorCode': result['errorCode'],
          'message': result['message']?.toString() ?? '获取群成员失败',
          'members': [],
          'creatorUserId': null,
        };
      }

      // 2. 解析返回的数据
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isEmpty) {
        return {
          'errorCode': 0,
          'message': '获取成功',
          'members': [],
          'creatorUserId': null,
        };
      }

      final map = json.decode(dataStr) as Map<String, dynamic>;
      final list = (map['members'] as List?) ?? [];

      if (list.isEmpty) {
        return {
          'errorCode': 0,
          'message': '获取成功',
          'members': [],
          'creatorUserId': null,
        };
      }

      // 3. 提取群主ID和所有用户ID
      String? creatorUserId;
      final userIds = <String>[];
      
      for (final e in list) {
        if (e is Map && e['is_admin'] == true) {
          creatorUserId = e['user_id'] as String?;
        }
        final userId = e['user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          userIds.add(userId);
        }
      }

      // 4. 从数据库批量获取用户信息（头像、昵称）
      final usersFromDb = await _messageDatabase.getUsers(userIds);
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersFromDb) {
        final userId = user['user_id'] as String?;
        if (userId != null) {
          userMap[userId] = user;
        }
      }

      // 5. 合并群成员数据和数据库中的用户信息
      final members = list.map((e) {
        if (e is! Map) return e;
        final member = Map<String, dynamic>.from(e.cast<String, dynamic>());
        final userId = member['user_id'] as String?;
        
        if (userId != null && userMap.containsKey(userId)) {
          final userInfo = userMap[userId]!;
          // 优先使用数据库中的头像和昵称（如果存在）
          if (userInfo['avatar'] != null && (userInfo['avatar'] as String).isNotEmpty) {
            member['avatar'] = userInfo['avatar'];
          }
          if (userInfo['nickname'] != null && (userInfo['nickname'] as String).isNotEmpty) {
            member['nickname'] = userInfo['nickname'];
          }
          // 同时添加 avatar_bg 字段
          if (userInfo['avatar_bg'] != null) {
            member['avatar_bg'] = userInfo['avatar_bg'];
          }
        }
        
        return member;
      }).toList();

      final responseData = {
        'errorCode': 0,
        'message': '获取成功',
        'members': members,
        'creatorUserId': creatorUserId,
      };

      // 6. 更新缓存（只缓存成功的结果）
      _membersCache[cacheKey] = {
        'data': responseData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      print('💾 已缓存群成员数据: $groupId');

      return responseData;
    } catch (e) {
      print('获取群成员失败: $e');
      return {
        'errorCode': -999,
        'message': '解析群成员失败: $e',
        'members': [],
        'creatorUserId': null,
      };
    }
  }

  /// 清除指定群组的缓存
  void clearGroupMembersCache(String groupId) {
    _membersCache.removeWhere((key, value) => key.startsWith('${groupId}_'));
    print('🗑️ 已清除群组缓存: $groupId');
  }

  /// 清除所有缓存
  void clearAllCache() {
    _membersCache.clear();
    print('🗑️ 已清除所有群成员缓存');
  }




  /// 获取群消息（带用户信息）
  /// 返回格式: { 'errorCode': int, 'message': String, 'data': String (JSON), 'has_more': bool, 'messages': List }
  Future<Map<String, dynamic>> getGroupMessages(
    String conversationId,
    String groupId, {
    int lastSeq = 0,
    int limit = 50,
  }) async {
    try {
      // 1. 请求群消息数据
      final result = await _nativeService.imPullGroupMessages(
        conversationId: conversationId,
        groupId: groupId,
        lastSeq: lastSeq,
        limit: limit,
      );

      if (result['errorCode'] != 0) {
        return result;
      }

      // 2. 解析返回的数据
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isEmpty) {
        return result;
      }

      final dataMap = json.decode(dataStr) as Map<String, dynamic>;
      final messages = (dataMap['messages'] as List?) ?? [];
      final hasMore = dataMap['has_more'] as bool? ?? false;

      if (messages.isEmpty) {
        return {
          ...result,
          'has_more': hasMore,
          'messages': [],
        };
      }

      // 3. 提取所有发送者ID（去重）
      final senderIds = <String>{};
      for (final msg in messages) {
        if (msg is Map) {
          final from = msg['from'] as String?;
          if (from != null && from.isNotEmpty) {
            senderIds.add(from);
          }
        }
      }

      // 4. 从数据库批量获取用户信息（头像、昵称）
      final usersFromDb = await _messageDatabase.getUsers(senderIds.toList());
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in usersFromDb) {
        final userId = user['user_id'] as String?;
        if (userId != null) {
          userMap[userId] = user;
        }
      }

      // 5. 合并消息数据和数据库中的用户信息
      final enrichedMessages = messages.map((msg) {
        if (msg is! Map) return msg;
        final message = Map<String, dynamic>.from(msg.cast<String, dynamic>());
        final from = message['from'] as String?;
        
        if (from != null && userMap.containsKey(from)) {
          final userInfo = userMap[from]!;
          // 添加或更新用户信息到消息中
          if (userInfo['avatar'] != null && (userInfo['avatar'] as String).isNotEmpty) {
            message['avatar'] = userInfo['avatar'];
          }
          if (userInfo['nickname'] != null && (userInfo['nickname'] as String).isNotEmpty) {
            message['nickname'] = userInfo['nickname'];
          }
          // 同时添加 avatar_bg 字段
          if (userInfo['avatar_bg'] != null) {
            message['avatar_bg'] = userInfo['avatar_bg'];
          }
        }
        
        return message;
      }).toList();

      // 6. 重新组装返回数据
      final enrichedDataMap = {
        'has_more': hasMore,
        'messages': enrichedMessages,
      };

      return {
        'errorCode': 0,
        'message': result['message'] ?? '获取成功',
        'reqId': result['reqId'],
        'data': json.encode(enrichedDataMap),
        'has_more': hasMore,
        'messages': enrichedMessages,
      };
    } catch (e) {
      print('获取群消息失败: $e');
      return {
        'errorCode': -999,
        'message': '解析群消息失败: $e',
        'data': '',
        'has_more': false,
        'messages': [],
      };
    }
  }
}