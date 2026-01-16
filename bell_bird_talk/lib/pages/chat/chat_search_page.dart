import 'dart:convert';

import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'models/chat_model.dart';
import 'chat_page.dart';

/// 搜索页面（搜索好友、群聊、聊天记录）
class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final IOSNativeService _nativeService = IOSNativeService();

  String _searchText = '';
  bool _isSearching = false;

  // 搜索结果
  List<Map<String, dynamic>> _contacts = [];
  List<ConversationModel> _groupConversations = [];
  List<Map<String, dynamic>> _messageConversations =
      []; // 包含 conversation 和 matchedMessage

  // 是否显示"查看更多"
  bool _showMoreContacts = false;
  bool _showMoreGroups = false;
  bool _showMoreMessages = false;

  @override
  void initState() {
    super.initState();

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

  /// 搜索
  Future<void> _onSearchChanged(String value) async {
    final keyword = value.trim();
    setState(() {
      _searchText = keyword;
    });

    if (keyword.isEmpty) {
      setState(() {
        _contacts = [];
        _groupConversations = [];
        _messageConversations = [];
        _showMoreContacts = false;
        _showMoreGroups = false;
        _showMoreMessages = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final userId = _globalCtrl.currentUser.value?.id ?? '';
    if (userId.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    try {
      // 1. 搜索好友
      final allContacts = await _messageDatabase.searchContacts(
        userId,
        keyword,
        limit: 100,
      );
      // _totalContacts = allContacts.length;
      _contacts = allContacts.take(2).toList();
      _showMoreContacts = allContacts.length > 2;

      // 2. 搜索群聊
      final allGroups = await _messageDatabase.searchGroupConversations(
        userId,
        keyword,
        limit: 100,
      );
      // _totalGroups = allGroups.length;
      _groupConversations = allGroups.take(2).toList();
      _showMoreGroups = allGroups.length > 2;

      // 3. 搜索聊天记录
      final allMessages = await _messageDatabase.searchMessageConversations(
        userId,
        keyword,
        limit: 100,
      );
      // _totalMessages = allMessages.length;
      _messageConversations = allMessages.take(2).toList();
      _showMoreMessages = allMessages.length > 2;
    } catch (e) {
      print('❌ 搜索失败: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

 
  /// 查看更多好友
  void _showMoreContactsList() {
    // TODO: 可以跳转到一个专门的好友搜索结果页面
    // 这里暂时显示所有结果
    _messageDatabase
        .searchContacts(
          _globalCtrl.currentUser.value?.id ?? '',
          _searchText,
          limit: 100,
        )
        .then((allContacts) {
          setState(() {
            _contacts = allContacts;
            _showMoreContacts = false;
          });
        });
  }

  /// 查看更多群聊
  void _showMoreGroupsList() {
    _messageDatabase
        .searchGroupConversations(
          _globalCtrl.currentUser.value?.id ?? '',
          _searchText,
          limit: 100,
        )
        .then((allGroups) {
          setState(() {
            _groupConversations = allGroups;
            _showMoreGroups = false;
          });
        });
  }

  /// 查看更多聊天记录
  void _showMoreMessagesList() {
    _messageDatabase
        .searchMessageConversations(
          _globalCtrl.currentUser.value?.id ?? '',
          _searchText,
          limit: 100,
        )
        .then((allMessages) {
          setState(() {
            _messageConversations = allMessages;
            _showMoreMessages = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightAppBarColorA,
      appBar: _buildSearchAppBar(),
      body: _searchText.isEmpty
          ? _buildInitialView()
          : (_isSearching ? _buildLoadingView() : _buildSearchResults()),
    );
  }

  /// 搜索 AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return PreferredSize(
      preferredSize: Size(Get.width, 64.h),
      child: SafeArea(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                 margin: EdgeInsets.only(left: 10),
                width: Get.width - 80,
                height: 44,
                decoration: BoxDecoration(
                  color: GbsColors.lightBackgroundA,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Padding(padding: EdgeInsetsGeometry.only(left: 12, right: 8), child: Icon(Icons.search, color: Colors.grey[400], size: 20),),
                    Expanded(child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: '搜索好友、群聊、聊天记录',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 15),
                        textInputAction: TextInputAction.search,
                      ))
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('取消'),
                ),
              ),
            ],
          ),
        
      ),
    );  }

  /// 初始视图
  Widget _buildInitialView() {
    return Center(
    );
  }

  /// 加载视图
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '搜索中...',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 搜索结果
  Widget _buildSearchResults() {
    final hasResults =
        _contacts.isNotEmpty ||
        _groupConversations.isNotEmpty ||
        _messageConversations.isNotEmpty;

    if (!hasResults) {
      return _buildEmptyResult();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 好友搜索结果
          if (_contacts.isNotEmpty) _buildContactsSection(),

          // 2. 群聊搜索结果
          if (_groupConversations.isNotEmpty) _buildGroupsSection(),

          // 3. 聊天记录搜索结果
          if (_messageConversations.isNotEmpty) _buildMessagesSection(),
        ],
      ),
    );
  }

  /// 好友搜索结果部分
  Widget _buildContactsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '好友',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          ..._contacts.map((contact) => _buildContactItem(contact)),
          if (_showMoreContacts)
            _buildMoreButton('查看更多', _showMoreContactsList),
        ],
      ),
    );
  }

  /// 群聊搜索结果部分
  Widget _buildGroupsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '群聊',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          ..._groupConversations.map((conv) => _buildConversationItem(conv)),
          if (_showMoreGroups) _buildMoreButton('查看更多', _showMoreGroupsList),
        ],
      ),
    );
  }

  /// 聊天记录搜索结果部分
  Widget _buildMessagesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '聊天记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          ..._messageConversations.map(
            (item) => _buildMessageConversationItem(item),
          ),
          if (_showMoreMessages)
            _buildMoreButton('查看更多', _showMoreMessagesList),
        ],
      ),
    );
  }

  /// 好友项
  Widget _buildContactItem(Map<String, dynamic> contact) {
    final contactUserId = contact['contact_user_id'] as String? ?? '';
    final nickname = contact['nickname'] as String? ?? '';
    final remark = contact['remark'] as String? ?? '';
    final avatar = contact['avatar'] as String? ?? '';
    final displayName = remark.isNotEmpty ? remark : nickname;
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _startChat(contactUserId, displayName, avatar);
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
                backgroundColor: Colors.blue,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
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
                    _buildHighlightText(displayName),
                    if (remark.isNotEmpty && remark != nickname) ...[
                      const SizedBox(height: 2),
                      Text(
                        '昵称: $nickname',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                    // 最后一条消息（如果有）
                    if (currentUserId.isNotEmpty)
                      FutureBuilder<ConversationModel?>(
                        future: _messageDatabase.getConversationByTargetId(
                          currentUserId,
                          contactUserId,
                          1, // convType: 1 = 单聊
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          
                          final conversation = snapshot.data;
                          final lastMessage = conversation?.lastMessage;
                          
                          if (lastMessage == null || lastMessage.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              _buildHighlightMessageText(lastMessage),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 发起聊天
  Future<void> _startChat(
    String friendId,
    String friendName,
    String avatar,
  ) async {
    try {
      // 获取当前用户ID
      final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
      // 1. 先查询本地数据库，看是否已有该好友的单聊会话
      final existingConv = await _messageDatabase.getConversationByTargetId(
        currentUserId,
        friendId,
        1, // convType: 1 = 单聊
      );

      if (existingConv != null) {
        Get.to(
          () => ChatPage(
            convId: existingConv.convId,
            displayName: existingConv.displayName,
            avatar: existingConv.avatar,
            targetUserId: friendId,
          ),
        )?.then((_) {
          // 返回后清除该会话的未读数
          ChatController.to.conversationId = "";
        });

        return;
      }

      // 2. 本地没有会话，调用 SDK 创建会话
      EasyLoading.show(status: '创建会话中...');

      final result = await _nativeService.imCreateConversation(
        convType: 1, // 单聊
        targetId: friendId,
        displayName: friendName,
        avatarUrl: avatar,
      );

      EasyLoading.dismiss();
      if (result['errorCode'] == 0) {
        // 解析返回的会话数据
        String convId = '';
        Map<String, dynamic>? convData;

        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            convData = json.decode(dataStr) as Map<String, dynamic>;
            convId = convData['conv_id']?.toString() ?? '';
          } catch (e) {
            print('⚠️ 解析会话数据失败: $e');
          }
        }

        // 如果没有获取到会话ID，使用默认格式
        if (convId.isEmpty) {
          convId = 'single_$friendId';
        }

        // 3. 保存会话到本地数据库
        if (convData != null) {
          try {
            final conversation = ConversationModel.fromJson(convData);
            await _messageDatabase.upsertConversation(
              currentUserId,
              conversation,
            );
            print('✅ 会话已保存到本地数据库: $convId');
          } catch (e) {
            print('⚠️ 保存会话到数据库失败: $e');
            // 即使保存失败，也继续跳转
          }
        } else {
          // 如果没有返回完整数据，创建一个基本的会话对象保存
          try {
            final conversation = ConversationModel(
              convId: convId,
              convType: 1,
              targetId: friendId,
              displayName: friendName,
              avatar: avatar,
            );
            await _messageDatabase.upsertConversation(
              currentUserId,
              conversation,
            );
            print('✅ 会话已保存到本地数据库: $convId');
          } catch (e) {
            print('⚠️ 保存会话到数据库失败: $e');
          }
        }

        // 4. 跳转到聊天页面
        Get.to(
          () => ChatPage(
            convId: convId,
            displayName: friendName,
            avatar: avatar,
            targetUserId: friendId,
          ),
        )?.then((_) {
          // 返回后清除该会话的未读数
          ChatController.to.conversationId = "";
        });
      } else {
        final message = result['message'] ?? '创建会话失败';
        EasyLoading.showError(message);
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('创建会话异常: $e');
      print('❌ 创建会话异常: $e');
    }
  }

  /// 会话项（用于群聊）
  Widget _buildConversationItem(ConversationModel conversation) {
    return _buildConversationItemWithMessage(
      conversation: conversation,
      displayMessage: conversation.lastMessage,
    );
  }

  /// 会话项（用于聊天记录，显示匹配的消息）
  Widget _buildMessageConversationItem(Map<String, dynamic> item) {
    final conversation = item['conversation'] as ConversationModel;
    final matchedMessage = item['matchedMessage'] as String?;
    return _buildConversationItemWithMessage(
      conversation: conversation,
      displayMessage: matchedMessage,
    );
  }

  /// 构建会话项（通用方法）
  Widget _buildConversationItemWithMessage({
    required ConversationModel conversation,
    String? displayMessage,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // 跳转到聊天页面
          Get.to(
            () => ChatPage(
              convId: conversation.convId,
              displayName: conversation.displayName,
              avatar: conversation.avatar,
              targetUserId: conversation.targetId ?? '',
              convType: conversation.convType,
            ),
          )?.then((_) {
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
                backgroundImage:
                    conversation.avatar != null &&
                        conversation.avatar!.isNotEmpty
                    ? NetworkImage(conversation.avatar!)
                    : null,
                child:
                    conversation.avatar == null || conversation.avatar!.isEmpty
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
                        Expanded(
                          child: _buildHighlightText(conversation.displayName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 显示的消息内容（匹配的消息或最后一条消息，支持高亮）
                    _buildHighlightMessageText(
                      displayMessage ?? conversation.lastMessage ?? '暂无消息',
                    ),
                  ],
                ),
              ),

              // 未读数
              if (conversation.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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

  /// 查看更多按钮
  Widget _buildMoreButton(String text, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text, style: TextStyle(fontSize: 14, color: GbsColors.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  /// 空结果
  Widget _buildEmptyResult() {
    return Center(
      child: EmptyView(),
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

  /// 高亮搜索词（用于标题）
  Widget _buildHighlightText(String text) {
    if (_searchText.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final searchLower = _searchText.toLowerCase();
    final matchIndex = lowerText.indexOf(searchLower);

    if (matchIndex == -1) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
          if (matchIndex > 0) TextSpan(text: text.substring(0, matchIndex)),
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

  /// 高亮搜索词（用于消息内容）
  Widget _buildHighlightMessageText(String text) {
    if (_searchText.isEmpty || text.isEmpty) {
      return Text(
        text.isEmpty ? '暂无消息' : text,
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final searchLower = _searchText.toLowerCase();
    final matchIndex = lowerText.indexOf(searchLower);

    if (matchIndex == -1) {
      return Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        children: [
          if (matchIndex > 0) TextSpan(text: text.substring(0, matchIndex)),
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
