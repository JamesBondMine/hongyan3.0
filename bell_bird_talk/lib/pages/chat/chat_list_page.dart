import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

/// 会话模型
class ConversationModel {
  final String convId;
  final String displayName;
  final String? avatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final int convType; // 0=单聊, 2=群聊, 3=系统, 4=社区
  final String? targetId;
  final bool isOnline;

  ConversationModel({
    required this.convId,
    required this.displayName,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.convType = 0,
    this.targetId,
    this.isOnline = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      convId: json['conv_id'] ?? '',
      displayName: json['display_name'] ?? '未知会话',
      avatar: json['avatar_url'],
      lastMessage: json['last_message'],
      lastMessageTime: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      convType: json['conv_type'] as int? ?? 0,
      targetId: json['target_id'],
      isOnline: (json['online_status'] as int? ?? 0) == 1,
    );
  }
}

/// 聊天列表页面
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreConversations();
    }
  }

  /// 加载会话列表
  Future<void> _loadConversations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final result = await _nativeService.imGetConversationList(
        page: 1,
        pageSize: 20,
      );

      print('📋 会话列表结果: $result');

      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            final conversations = dataMap['conversations'] as List<dynamic>?;
            if (conversations != null) {
              _conversations = conversations
                  .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              _hasMore = conversations.length >= 20;
            }
          } catch (e) {
            print('解析会话列表失败: $e');
          }
        }
        _filterConversations();
      } else {
        // 如果没有数据，显示空列表
        _conversations = [];
        _filteredConversations = [];
      }
    } catch (e) {
      print('加载会话列表错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载更多会话
  Future<void> _loadMoreConversations() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _nativeService.imGetConversationList(
        page: _currentPage + 1,
        pageSize: 20,
      );

      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            final conversations = dataMap['conversations'] as List<dynamic>?;
            if (conversations != null && conversations.isNotEmpty) {
              _conversations.addAll(
                conversations
                    .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                    .toList(),
              );
              _currentPage++;
              _hasMore = conversations.length >= 20;
            } else {
              _hasMore = false;
            }
          } catch (e) {
            print('解析会话列表失败: $e');
          }
        }
        _filterConversations();
      }
    } catch (e) {
      print('加载更多会话错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新会话列表
  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  /// 过滤会话
  void _filterConversations() {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      _filteredConversations = List.from(_conversations);
    } else {
      _filteredConversations = _conversations
          .where((conv) =>
              conv.displayName.toLowerCase().contains(keyword) ||
              (conv.lastMessage?.toLowerCase().contains(keyword) ?? false))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showNewChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          
          // 会话列表
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '搜索会话',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onChanged: (value) => _filterConversations(),
        ),
      ),
    );
  }

  /// 构建会话列表
  Widget _buildConversationList() {
    if (_isLoading && _conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredConversations.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _refreshConversations,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _filteredConversations.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredConversations.length) {
            return _buildLoadingIndicator();
          }
          return _buildConversationItem(_filteredConversations[index]);
        },
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无聊天记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去找好友聊天吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewChatOptions,
            icon: const Icon(Icons.add),
            label: const Text('发起聊天'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建会话项
  Widget _buildConversationItem(ConversationModel conversation) {
    return InkWell(
      onTap: () => _openChat(conversation),
      onLongPress: () => _showConversationOptions(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // 头像
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(conversation.convType),
                  backgroundImage: conversation.avatar != null
                      ? NetworkImage(conversation.avatar!)
                      : null,
                  child: conversation.avatar == null
                      ? Text(
                          _getAvatarText(conversation),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // 在线状态指示器
                if (conversation.convType == 0 && conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            // 会话信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 会话类型图标
                      if (conversation.convType == 2)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.group,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      // 会话名称
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 时间
                      if (conversation.lastMessageTime != null)
                        Text(
                          _formatTime(conversation.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // 最后一条消息
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? '暂无消息',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 未读数
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// 获取头像背景色
  Color _getAvatarColor(int convType) {
    switch (convType) {
      case 0:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 获取头像文字
  String _getAvatarText(ConversationModel conversation) {
    if (conversation.displayName.isEmpty) return '?';
    return conversation.displayName.substring(0, 1).toUpperCase();
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // 今天
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天';
    } else if (difference.inDays < 7) {
      // 一周内
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else {
      // 更早
      return '${time.month}/${time.day}';
    }
  }

  /// 打开聊天
  void _openChat(ConversationModel conversation) {
    EasyLoading.showInfo('打开会话: ${conversation.displayName}');
    // TODO: 跳转到聊天详情页
    // Get.to(() => ChatDetailPage(conversation: conversation));
  }

  /// 显示会话选项
  void _showConversationOptions(ConversationModel conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('置顶会话'),
              onTap: () {
                Navigator.pop(context);
                EasyLoading.showInfo('置顶会话');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('消息免打扰'),
              onTap: () {
                Navigator.pop(context);
                EasyLoading.showInfo('消息免打扰');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined),
              title: const Text('标记已读'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除会话', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 显示新建聊天选项
  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: Colors.blue),
              title: const Text('发起单聊'),
              subtitle: const Text('选择好友开始聊天'),
              onTap: () {
                Navigator.pop(context);
                EasyLoading.showInfo('发起单聊');
                // TODO: 跳转到好友列表选择
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined, color: Colors.green),
              title: const Text('创建群聊'),
              subtitle: const Text('邀请多人加入群聊'),
              onTap: () {
                Navigator.pop(context);
                EasyLoading.showInfo('创建群聊');
                // TODO: 跳转到创建群聊页面
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 标记已读
  Future<void> _markAsRead(ConversationModel conversation) async {
    try {
      final result = await _nativeService.imMarkConversationRead(
        convId: conversation.convId,
      );
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('已标记为已读');
        _refreshConversations();
      } else {
        EasyLoading.showError('操作失败');
      }
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
    }
  }

  /// 删除会话
  Future<void> _deleteConversation(ConversationModel conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除与"${conversation.displayName}"的会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _nativeService.imDeleteConversation(
          convId: conversation.convId,
        );
        if (result['errorCode'] == 0) {
          EasyLoading.showSuccess('已删除');
          _refreshConversations();
        } else {
          EasyLoading.showError('删除失败');
        }
      } catch (e) {
        EasyLoading.showError('删除失败: $e');
      }
    }
  }
}

