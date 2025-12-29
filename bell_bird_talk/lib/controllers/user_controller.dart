import 'package:get/get.dart';
import '../services/native_bridge.dart';
import '../services/message_database.dart';
import 'dart:convert';

class UserController extends GetxController { 

  static UserController get to => Get.put(UserController());

  final IOSNativeService _nativeService = IOSNativeService();

  /// 获取联系人列表
  Future<Map<String, dynamic>> getContactList({
    required int page,
    required int pageSize,
    int? groupId,
    required int relationship,
  }) async {
    final result = await _nativeService.imGetContactList(
      page: page,
      pageSize: pageSize,
      groupId: groupId,
      relationship: relationship,
    );

    // 如果获取成功，更新数据库中的用户信息
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        final data = json.decode(dataStr);
        final contactsJson = data['contacts'] as List? ?? [];

        // 提取用户信息用于更新数据库
        final usersInfo = contactsJson.map((contact) {
          return {
            'user_id': contact['contact_user_id'] ?? '',
            'nickname': contact['nickname'] ?? '',
            'avatar': contact['avatar'] ?? '',
            'account_id': contact['account_id'] ?? '',
            'online_status': contact['online_status'] ?? 0,
            'phone': contact['phone'] ?? contact['target_phone'] ?? '',
            'email': contact['email'] ?? contact['target_email'] ?? '',
            // 其他字段使用默认值或空
            'sex': 0,
            'signature': null,
            'region': null,
            'background_file': null,
            'last_online_time': null,
          };
        }).toList();

        // 批量更新用户信息到数据库
        if (usersInfo.isNotEmpty) {
          await MessageDatabase().upsertUsers(usersInfo);
        }
      }
    }

    return result;
  }

  /// 获取好友申请列表（包含申请者的公开信息）
  /// 
  /// [status] 申请状态：0=待处理, 1=已同意, 2=已拒绝
  /// [page] 页码，从1开始
  /// [pageSize] 每页数量
  /// 
  /// 返回格式：
  /// {
  ///   'errorCode': 0,
  ///   'data': {
  ///     'page': 1,
  ///     'total_count': 3,
  ///     'requests': [
  ///       {
  ///         'request_id': ...,
  ///         'requester_id': ...,
  ///         'requester_name': ...,
  ///         'requester_avatar': ...,  // 已填充的公开信息
  ///         'avatar': ...,             // 公开信息中的头像
  ///         'nickname': ...,           // 公开信息中的昵称
  ///         ...
  ///       }
  ///     ]
  ///   }
  /// }
  Future<Map<String, dynamic>> getFriendRequests({
    required int status,
    required int page,
    required int pageSize,
  }) async {
    try {
      // 1. 获取好友申请列表
      final result = await _nativeService.imGetFriendRequests(
        status: status,
        page: page,
        pageSize: pageSize,
      );

      if (result['errorCode'] != 0) {
        return result;
      }

      final dataStr = result['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) {
        return {
          ...result,
          'data': json.encode({'page': page, 'total_count': 0, 'requests': []}),
        };
      }

      final data = json.decode(dataStr);
      final requestsJson = data['requests'] as List? ?? [];

      if (requestsJson.isEmpty) {
        return result;
      }

      // 2. 提取所有申请者的用户ID
      final requesterIds = <String>[];
      for (final request in requestsJson) {
        final requesterId = request['requester_id'] as String?;
        if (requesterId != null && requesterId.isNotEmpty && !requesterIds.contains(requesterId)) {
          requesterIds.add(requesterId);
        }
      }

      if (requesterIds.isEmpty) {
        return result;
      }

      // 3. 批量获取申请者的公开信息
      final publicInfoResult = await _nativeService.imBatchGetUserPublicInfo(
        userIds: requesterIds,
      );

      if (publicInfoResult['errorCode'] == 0) {
        final publicInfoStr = publicInfoResult['data'] as String? ?? '';
        if (publicInfoStr.isNotEmpty) {
          try {
            final publicInfoList = json.decode(publicInfoStr) as List<dynamic>;
            final publicInfoMap = <String, Map<String, dynamic>>{};

            // 将公开信息按用户ID索引
            for (final info in publicInfoList) {
              if (info is Map<String, dynamic>) {
                final userId = info['user_id'] as String?;
                if (userId != null) {
                  publicInfoMap[userId] = info;
                }
              }
            }

            // 4. 合并公开信息到好友申请数据中
            final enrichedRequests = requestsJson.map((request) {
              final requesterId = request['requester_id'] as String?;
              if (requesterId != null && publicInfoMap.containsKey(requesterId)) {
                final publicInfo = publicInfoMap[requesterId]!;
                // 合并公开信息，优先使用公开信息中的字段
                return {
                  ...request,
                  'requester_avatar': publicInfo['avatar'] ?? request['requester_avatar'],
                  'avatar': publicInfo['avatar'],
                  'nickname': publicInfo['nickname'] ?? request['requester_name'],
                  'sex': publicInfo['sex'],
                  'signature': publicInfo['signature'],
                  'region': publicInfo['region'],
                  'background_file': publicInfo['background_file'],
                  'avatar_bg': publicInfo['avatar_bg'],
                  // 保留其他公开信息字段
                  ...publicInfo,
                };
              }
              return request;
            }).toList();

            // 5. 更新返回数据
            final enrichedData = {
              ...data,
              'requests': enrichedRequests,
            };

            // 6. 存储用户信息到数据库
            final usersToStore = publicInfoList
                .where((info) => info is Map<String, dynamic>)
                .map((info) => info as Map<String, dynamic>)
                .toList();

            if (usersToStore.isNotEmpty) {
              await MessageDatabase().upsertUsers(usersToStore);
              print('💾 已存储 ${usersToStore.length} 个申请者信息到数据库');
            }

            print('✅ 已为 ${publicInfoMap.length} 个好友申请添加公开信息');

            return {
              ...result,
              'data': json.encode(enrichedData),
            };
          } catch (e) {
            print('❌ 解析公开信息失败: $e');
            // 如果解析失败，返回原始结果
            return result;
          }
        } else {
          // 公开信息为空，返回原始结果
          return result;
        }
      } else {
        print('⚠️ 获取申请者公开信息失败: ${publicInfoResult['message']}');
        // 如果获取公开信息失败，返回原始结果
        return result;
      }
    } catch (e) {
      print('❌ 获取好友申请异常: $e');
      return {
        'errorCode': -1,
        'message': '获取好友申请失败: $e',
      };
    }
  }

}