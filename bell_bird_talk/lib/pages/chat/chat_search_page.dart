import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/chat_model.dart';
import 'chat_page.dart';

/// 会话搜索页面
class ChatSearchPage extends StatefulWidget {
  final List<ConversationModel> conversations;

  const ChatSearchPage({
    super.key,
    required this.conversations,
  });

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<ConversationModel> _filteredConversations = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _filteredConversations = [];
    
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 搜索过滤
  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim().toLowerCase();
      if (_searchText.isEmpty) {
        _filteredConversations = [];
      } else {
        _filteredConversations = widget.conversations.where((conv) {
          final displayName = conv.displayName.toLowerCase();
          final lastMessage = (conv.lastMessage ?? '').toLowerCase();
          final convId = conv.convId.toLowerCase();
          return displayName.contains(_searchText) ||
                 lastMessage.contains(_searchText) ||
                 convId.contains(_searchText);
        }).toList();
      }
    });
  }

  /// 清空搜索
  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildSearchAppBar(),
      body: Column(
        children: [
          // 搜索结果统计
          if (_searchText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              width: double.infinity,
              child: Text(
                '找到 ${_filteredConversations.length} 个会话',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
          
          // 会话列表
          Expanded(
            child: _searchText.isEmpty
                ? _buildInitialView()
                : (_filteredConversations.isEmpty
                    ? _buildEmptyResult()
                    : _buildConversationList()),
          ),
        ],
      ),
    );
  }

  /// 搜索 AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索会话、消息内容',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(fontSize: 15),
        textInputAction: TextInputAction.search,
      ),
      actions: [
        if (_searchText.isNotEmpty)
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: _clearSearch,
          ),
      ],
    );
  }

  /// 初始视图
  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '输入关键词搜索会话',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可搜索会话名称、消息内容',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 空结果
  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的会话',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他关键词',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 会话列表
  Widget _buildConversationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return _buildConversationItem(conversation);
      },
    );
  }

  /// 会话项
  Widget _buildConversationItem(ConversationModel conversation) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // 跳转到聊天页面
          Get.to(() => ChatPage(
            convId: conversation.convId,
            displayName: conversation.displayName,
            avatar: conversation.avatar,
            targetUserId: conversation.targetId ?? '',
          ))?.then(  (_) {
            // 返回后清除该会话的未读数
            ChatController.to.conversationId = "";
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(conversation.convType),
                backgroundImage: conversation.avatar != null && conversation.avatar!.isNotEmpty
                    ? NetworkImage(conversation.avatar!)
                    : null,
                child: conversation.avatar == null || conversation.avatar!.isEmpty
                    ? Text(
                        conversation.displayName.isNotEmpty 
                            ? conversation.displayName[0].toUpperCase() 
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称（高亮搜索词）
                    Row(
                      children: [
                        if (conversation.convType == 2)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.group,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        Expanded(
                          child: _buildHighlightText(conversation.displayName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 最后一条消息
                    Text(
                      conversation.lastMessage ?? '暂无消息',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 未读数
              if (conversation.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    conversation.unreadCount > 99 
                        ? '99+' 
                        : conversation.unreadCount.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
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

  /// 高亮搜索词
  Widget _buildHighlightText(String text) {
    if (_searchText.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final matchIndex = lowerText.indexOf(_searchText);
    
    if (matchIndex == -1) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + _searchText.length),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (matchIndex + _searchText.length < text.length)
            TextSpan(text: text.substring(matchIndex + _searchText.length)),
        ],
      ),
    );
  }
}

