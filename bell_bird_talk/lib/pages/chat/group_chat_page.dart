import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    // 直接使用 ChatPage，传入自定义导航栏以避免双 AppBar
    return ChatPage(
      convId: widget.convId,
      displayName: widget.groupName,
      avatar: widget.groupAvatar,
      targetUserId: widget.groupId,
      convType: 2, // 群聊
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


