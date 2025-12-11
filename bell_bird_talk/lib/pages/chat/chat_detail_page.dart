import 'package:flutter/material.dart';

/// 会话详情页面
class ChatDetailPage extends StatefulWidget {
  final String convId;
  final String targetId;
  final String displayName;
  final String avatarUrl;
  final int convType; // 0: 单聊, 1: 群聊, 2: 社群

  const ChatDetailPage({
    super.key,
    required this.convId,
    required this.targetId,
    required this.displayName,
    this.avatarUrl = '',
    this.convType = 0,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天详情'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 头像
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.avatarUrl)
                  : null,
              child: widget.avatarUrl.isEmpty
                  ? Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // 名称
            Text(
              widget.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // ID
            Text(
              'ID: ${widget.targetId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            // 占位提示
            Text(
              '更多功能开发中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

