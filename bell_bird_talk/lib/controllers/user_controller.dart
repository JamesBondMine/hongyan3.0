import 'package:bell_bird_talk/models/user_model.dart';
import 'package:get/get.dart';
import '../services/native_bridge.dart';
import '../services/message_database.dart';
import '../controllers/global_controller.dart';
import 'dart:convert';

class UserController extends GetxController { 

  static UserController get to => Get.put(UserController());

  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();

  /// 获取联系人列表
  /// 
  /// [page] 页码，从1开始
  /// [pageSize] 每页数量
  /// [groupId] 分组ID（可选，null表示不按分组过滤）
  /// [relationship] 关系类型：-1=全部, 0=好友, 1=黑名单等
  /// [forceRefresh] 是否强制从网络获取（默认false）
  /// [keyword] 搜索关键词，支持搜索nickname、phone、email、remark（可选）
  Future<Map<String, dynamic>> getContactList({
    required int page,
    required int pageSize,
    int? groupId,
    required int relationship,
    bool forceRefresh = false,
    String? keyword,
  }) async {
    // 获取当前用户ID
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    if (currentUserId.isEmpty) {
      return {
        'errorCode': -1,
        'message': '用户未登录',
        'data': json.encode({'contacts': [], 'total_count': 0}),
      };
    }

    // 如果有搜索关键词或强制刷新，直接从网络获取
    if (keyword != null && keyword.isNotEmpty) {
      return await _fetchContactsFromNetwork(
        currentUserId: currentUserId,
        page: page,
        pageSize: pageSize,
        groupId: groupId,
        relationship: relationship,
        keyword: keyword,
      );
    }

    if (forceRefresh) {
      // 强制刷新：分页获取全部联系人
      print('📋 强制刷新，从网络获取全部联系人');
      if (page == 1) {
        // 第一页时，重新获取全部联系人
        await _fetchAllContactsInBatches(
          currentUserId: currentUserId,
          groupId: groupId,
          relationship: relationship,
        );
        // 返回第一页数据
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: 1,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      } else {
        // 后续页面从数据库获取
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: page,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      }
    }

    // 检查数据库中是否有联系人数据
    final dbContacts = await _messageDatabase.getAllContacts(currentUserId);
    final hasDbContacts = dbContacts.isNotEmpty;

    if (!hasDbContacts) {
      // 第一次加载：分页获取全部联系人
      print('📋 数据库中没有联系人数据，从网络分页获取全部联系人');
      if (page == 1) {
        // 第一次调用时，循环获取所有联系人
        await _fetchAllContactsInBatches(
          currentUserId: currentUserId,
          groupId: groupId,
          relationship: relationship,
        );
        // 返回第一页数据
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: 1,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      } else {
        // 后续页面从数据库获取
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: page,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      }
    }

    // 检查数据库中的联系人数据是否超过24小时
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);
    
    // 获取最早更新的联系人的更新时间
    final oldestUpdatedContact = dbContacts
        .map((c) => c['updated_at'] as int? ?? 0)
        .where((t) => t > 0)
        .fold<int?>(null, (prev, curr) => prev == null || curr < prev ? curr : prev);

    final needRefresh = oldestUpdatedContact == null || oldestUpdatedContact < twentyFourHoursAgo;

    if (needRefresh) {
      // 超过24小时，从网络获取并更新
      print('📋 联系人数据超过24小时，从网络获取并更新');
      if (page == 1) {
        // 第一页时，重新获取全部联系人
        await _fetchAllContactsInBatches(
          currentUserId: currentUserId,
          groupId: groupId,
          relationship: relationship,
        );
        // 返回第一页数据
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: 1,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      } else {
        // 后续页面从数据库获取
        return await _getContactsFromDatabase(
          currentUserId: currentUserId,
          page: page,
          pageSize: pageSize,
          groupId: groupId,
          relationship: relationship,
        );
      }
    } else {
      // 从数据库获取
      return await _getContactsFromDatabase(
        currentUserId: currentUserId,
        page: page,
        pageSize: pageSize,
        groupId: groupId,
        relationship: relationship,
      );
    }
  }

  /// 循环获取所有联系人（用于第一次加载）
  Future<void> _fetchAllContactsInBatches({
    required String currentUserId,
    int? groupId,
    required int relationship,
  }) async {
    const pageSize = 50; // 每批获取50条
    int currentPage = 1;
    bool hasMore = true;

    while (hasMore) {
      final result = await _nativeService.imGetContactList(
        page: currentPage,
        pageSize: pageSize,
        groupId: groupId,
        relationship: relationship,
      );

      if (result['errorCode'] != 0) {
        print('❌ 获取联系人失败: ${result['message']}');
        break;
      }

      final dataStr = result['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) {
        hasMore = false;
        break;
      }

      final data = json.decode(dataStr);
      final contactsJson = data['contacts'] as List? ?? [];

      if (contactsJson.isEmpty) {
        hasMore = false;
        break;
      }

      // 存储到数据库
      final contacts = contactsJson
          .map((json) => json as Map<String, dynamic>)
          .toList();
      await _messageDatabase.saveContacts(currentUserId, contacts);

      // 同时更新users表
      final usersInfo = contactsJson.map((contact) {
        return {
          'user_id': contact['contact_user_id'] ?? '',
          'nickname': contact['nickname'] ?? '',
          'avatar': contact['avatar'] ?? '',
          'groupId': contact['groupId'] ?? '',
          'account_id': contact['account_id'] ?? '',
          'online_status': contact['online_status'] ?? 0,
          'phone': contact['phone'] ?? contact['target_phone'] ?? '',
          'email': contact['email'] ?? contact['target_email'] ?? '',
          'sex': 0,
          'signature': null,
          'region': null,
          'background_file': null,
          'last_online_time': null,
        };
      }).toList();

      if (usersInfo.isNotEmpty) {
        await _messageDatabase.upsertUsers(usersInfo);
      }

      print('📋 已获取并存储第 $currentPage 页联系人，共 ${contacts.length} 条');

      // 如果返回的数据少于pageSize，说明已经是最后一页
      if (contacts.length < pageSize) {
        hasMore = false;
      } else {
        currentPage++;
      }
    }

    print('✅ 已获取并存储全部联系人，共 $currentPage 页');
  }

  /// 从网络分页获取全部联系人（用于强制刷新或超过24小时）
  Future<Map<String, dynamic>> _fetchAllContactsFromNetwork({
    required String currentUserId,
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

    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        final data = json.decode(dataStr);
        final contactsJson = data['contacts'] as List? ?? [];

        // 存储联系人到数据库（contacts表）
        if (contactsJson.isNotEmpty) {
          final contacts = contactsJson
              .map((json) => json as Map<String, dynamic>)
              .toList();
          await _messageDatabase.saveContacts(currentUserId, contacts);
          print('💾 已存储 ${contacts.length} 个联系人到数据库');
        }

        // 同时更新users表（用于用户信息查询）
        final usersInfo = contactsJson.map((contact) {
          return {
            'user_id': contact['contact_user_id'] ?? '',
            'nickname': contact['nickname'] ?? '',
            'avatar': contact['avatar'] ?? '',
            'groupId': contact['groupId'] ?? '',
            'account_id': contact['account_id'] ?? '',
            'online_status': contact['online_status'] ?? 0,
            'phone': contact['phone'] ?? contact['target_phone'] ?? '',
            'email': contact['email'] ?? contact['target_email'] ?? '',
            'sex': 0,
            'signature': null,
            'region': null,
            'background_file': null,
            'last_online_time': null,
          };
        }).toList();

        if (usersInfo.isNotEmpty) {
          await _messageDatabase.upsertUsers(usersInfo);
        }
      }
    }

    return result;
  }

  /// 从网络获取联系人（带关键词搜索）
  Future<Map<String, dynamic>> _fetchContactsFromNetwork({
    required String currentUserId,
    required int page,
    required int pageSize,
    int? groupId,
    required int relationship,
    String? keyword,
  }) async {
    final result = await _nativeService.imGetContactList(
      page: page,
      pageSize: pageSize,
      groupId: groupId,
      relationship: relationship,
      keyword: keyword,
    );

    // 搜索时也更新数据库（但不作为主要数据源）
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        final data = json.decode(dataStr);
        final contactsJson = data['contacts'] as List? ?? [];

        if (contactsJson.isNotEmpty) {
          final contacts = contactsJson
              .map((json) => json as Map<String, dynamic>)
              .toList();
          await _messageDatabase.saveContacts(currentUserId, contacts);
          
          // 同时更新users表
          final usersInfo = contactsJson.map((contact) {
            return {
              'user_id': contact['contact_user_id'] ?? '',
              'nickname': contact['nickname'] ?? '',
              'avatar': contact['avatar'] ?? '',
              'groupId': contact['groupId'] ?? '',
              'account_id': contact['account_id'] ?? '',
              'online_status': contact['online_status'] ?? 0,
              'phone': contact['phone'] ?? contact['target_phone'] ?? '',
              'email': contact['email'] ?? contact['target_email'] ?? '',
              'sex': 0,
              'signature': null,
              'region': null,
              'background_file': null,
              'last_online_time': null,
            };
          }).toList();

          if (usersInfo.isNotEmpty) {
            await _messageDatabase.upsertUsers(usersInfo);
          }
        }
      }
    }

    return result;
  }

  /// 从数据库获取联系人
  Future<Map<String, dynamic>> _getContactsFromDatabase({
    required String currentUserId,
    required int page,
    required int pageSize,
    int? groupId,
    required int relationship,
  }) async {
    try {
      // 查询所有联系人
      List<Map<String, dynamic>> allContacts = await _messageDatabase.getAllContacts(currentUserId);

      // 按分组过滤
      if (groupId != null && groupId > 0) {
        allContacts = allContacts.where((contact) {
          final contactGroupId = contact['group_id'] as int?;
          return contactGroupId == groupId;
        }).toList();
      }

      // 按关系类型过滤
      if (relationship >= 0) {
        allContacts = allContacts.where((contact) {
          final contactRelationship = contact['relationship'] as int? ?? 0;
          return contactRelationship == relationship;
        }).toList();
      }

      // 分页处理
      final totalCount = allContacts.length;
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      final paginatedContacts = allContacts.sublist(
        startIndex < totalCount ? startIndex : totalCount,
        endIndex < totalCount ? endIndex : totalCount,
      );

      // 转换为接口格式
      final contactsJson = paginatedContacts.map((contact) {
        return {
          'contact_user_id': contact['contact_user_id'],
          'nickname': contact['nickname'],
          'avatar': contact['avatar'],
          'remark_name': contact['remark_name'],
          'remark': contact['remark'],
          'phone': contact['phone'],
          'email': contact['email'],
          'account_id': contact['account_id'],
          'relationship': contact['relationship'],
          'online_status': contact['online_status'],
          'group_id': contact['group_id'],
          'group_name': contact['group_name'],
        };
      }).toList();

      return {
        'errorCode': 0,
        'message': '获取成功',
        'data': json.encode({
          'contacts': contactsJson,
          'total_count': totalCount,
          'page': page,
          'page_size': pageSize,
        }),
      };
    } catch (e) {
      print('❌ 从数据库获取联系人失败: $e');
      // 如果数据库查询失败，回退到网络获取
      return await _fetchAllContactsFromNetwork(
        currentUserId: currentUserId,
        page: page,
        pageSize: pageSize,
        groupId: groupId,
        relationship: relationship,
      );
    }
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
              await _messageDatabase.upsertUsers(usersToStore);
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



  // 获取用户信息--数据库
  Future<List<UserModel>> getUsersInfo(List<String> targetIds) async {
    final users = await _messageDatabase.getUsers(targetIds.toList());
      return users.map((user) {
        return UserModel.fromJson(user);
      }).toList();
  }

}