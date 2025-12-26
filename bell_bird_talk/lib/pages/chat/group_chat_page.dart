import 'dart:convert';
import 'package:bell_bird_talk/controllers/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import '../../services/native_bridge.dart';
import '../../services/message_database.dart';
import 'chat_page.dart';
import 'group_detail_page.dart';

/// 群聊会话页面（业务上独立于单聊）
/// 对外只暴露群相关参数，内部复用 ChatPage 的通用实现。
class GroupChatPage extends StatefulWidget {
  final String convId;
  final String groupId;
  final String groupName;
  final String? groupAvatar;

  const GroupChatPage({
    super.key,
    required this.convId,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  List<Map<String, dynamic>> _groupMembers = [];
  bool? _isMuted; // 是否禁言

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _loadGroupInfo();
  }

  Future<void> _loadGroupMembers() async {
    try {
      final result = await GroupController.to.getGroupMembersFullInfo(
      widget.groupId,
      page: 1,
      pageSize: 200,
    );
      if (!mounted) return;
      if (result['errorCode'] == 0) {
        final dataStr = result as Map<String, dynamic>? ?? {};
        if (dataStr.isNotEmpty) {
          try {
            final map = json.decode(json.encode(dataStr)) as Map<String, dynamic>;
            final list = (map['members'] as List?) ?? [];
            final members = list.map((e) => (e as Map).cast<String, dynamic>()).toList();
            
            // 提取用户ID列表
            final userIds = members
                .map((member) => member['user_id'] as String?)
                .where((id) => id != null && id.isNotEmpty)
                .cast<String>()
                .toList();
            
            setState(() {
              _groupMembers = members;
            });
            
            // 如果有用户ID，批量获取公开信息
            if (userIds.isNotEmpty) {
              await _loadGroupMembersPublicInfo(userIds);
            }
          } catch (e) {
            print('解析群成员失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取群成员失败: $e');
    }
  }

  /// 批量获取群成员的公开信息
  Future<void> _loadGroupMembersPublicInfo(List<String> userIds) async {
    try {
      final result = await _nativeService.imBatchGetUserPublicInfo(userIds: userIds);
      if (!mounted) return;
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final publicInfoList = json.decode(dataStr) as List<dynamic>;
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
            
            // 获取需要更新的用户ID列表（超过8小时未更新）
            final usersNeedUpdate = await _messageDatabase.getUsersNeedUpdate(8);
            final usersToUpdate = userIds.where((userId) => 
              !usersNeedUpdate.contains(userId) || usersNeedUpdate.contains(userId)
            ).toList();
            
            // 过滤出需要存储的用户信息
            final usersToStore = publicInfoList
                .where((info) => info is Map<String, dynamic>)
                .map((info) => info as Map<String, dynamic>)
                .where((info) {
                  final userId = info['user_id'] as String?;
                  return userId != null && usersToUpdate.contains(userId);
                })
                .toList();
            
            // 批量存储用户信息到数据库
            if (usersToStore.isNotEmpty) {
              await _messageDatabase.upsertUsers(usersToStore);
              print('💾 已存储 ${usersToStore.length} 个用户信息到数据库');
            }
            
            // 更新群成员信息，合并公开信息
            setState(() {
              _groupMembers = _groupMembers.map((member) {
                final userId = member['user_id'] as String?;
                if (userId != null && publicInfoMap.containsKey(userId)) {
                  return {...member, ...publicInfoMap[userId]!};
                }
                return member;
              }).toList();
            });
            
            print('✅ 已更新 ${publicInfoMap.length} 个群成员的公开信息');
          } catch (e) {
            print('解析群成员公开信息失败: $e');
          }
        }
      } else {
        print('批量获取群成员公开信息失败: ${result['message']}');
      }
    } catch (e) {
      print('批量获取群成员公开信息错误: $e');
    }
  }

  Future<void> _loadGroupInfo() async {
    try {
      final result = await _nativeService.imGetGroupInfo(groupId: widget.groupId);
      if (!mounted) return;
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final map = json.decode(dataStr) as Map<String, dynamic>;
            final isMuted = map['is_muted'] as bool? ?? false;
            setState(() {
              _isMuted = isMuted;
            });
          } catch (e) {
            print('解析群信息失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取群信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接使用 ChatPage，传入自定义导航栏以避免双 AppBar
    return ChatPage(
      convId: widget.convId,
      displayName: widget.groupName,
      avatar: widget.groupAvatar,
      targetUserId: widget.groupId,
      convType: 2, // 群聊
      groupMembers: _groupMembers, // 传递群成员列表
      isMuted: _isMuted, // 传递禁言状态
      customAppBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailPage(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    groupAvatar: widget.groupAvatar,
                  ),
                ),
              );
            },
          ),
          CustomPopup(
          // contentPadding: EdgeInsets.only(right: 16),
  content: Column(
  mainAxisSize: MainAxisSize.min,
    children: _buildAppBarActions()
  ),
  child: Image.asset('assets/img/chat/chatadd.png', width: 24, height: 24),
),SizedBox(width: 16,)
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      popviewItem(context, '语音聊天', 'assets/img/chat/chataddchat.png', () {
        print('发起群聊'); }),
        popviewItem(context, '添加好友', 'assets/img/chat/chataddchat.png', () {
        print('发起群聊'); }),
        popviewItem(context, '搜索聊天', 'assets/img/chat/chataddchat.png', () {
        print('发起群聊'); }),
        popviewItem(context, '免打扰', 'assets/img/chat/chataddchat.png', () {
        print('发起群聊'); }),
        popviewItem(context, '更多设置', 'assets/img/chat/chataddchat.png', () {
        print('发起群聊'); })
    ];
  }


  Widget popviewItem(BuildContext context, String title, String imgPath, VoidCallback onTap) { 
    return
        GestureDetector(
        child: Container(
          alignment: Alignment.center,
          width: 120,
          padding: const EdgeInsets.only(top: 10, bottom: 6, left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('assets/img//chat/chataddchat.png', width: 20, height: 20),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
        ),
        onTap: () {
          Navigator.pop(  context); // 先关闭弹出菜单
          onTap();
          // _createGroup();
        });
  }
}


