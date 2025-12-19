import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/native_bridge.dart';
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
      final result = await _nativeService.imGetGroupMembers(
        groupId: widget.groupId,
        page: 1,
        pageSize: 200,
      );
      if (!mounted) return;
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final map = json.decode(dataStr) as Map<String, dynamic>;
            final list = (map['members'] as List?) ?? [];
            setState(() {
              _groupMembers = list.map((e) => (e as Map).cast<String, dynamic>()).toList();
            });
          } catch (e) {
            print('解析群成员失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取群成员失败: $e');
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
        ],
      ),
    );
  }
}


