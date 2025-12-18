import 'dart:convert';
import 'package:bell_bird_talk/pages/chat/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';
import '../../services/message_database.dart';
import '../profile/side_menu_page.dart';
import 'chat_page.dart';
import 'chat_search_page.dart';
import 'create_group_page.dart';



/// 聊天列表页面
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isLoading = false;
  bool _isLoadingFromNetwork = false;  // 网络加载状态
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isSearchMode = false;
  int _filterType = 0; // 0=全部, 1=未读, 2=群聊, 3=@我的
  
  Worker? _refreshWorker;
  Worker? _newMessageWorker;
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  
  /// 获取当前用户ID
  String get _currentUserId => _globalCtrl.currentUser.value?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _scrollController.addListener(_onScroll);
    
    // 监听全局刷新信号
    _refreshWorker = ever(
      _globalCtrl.refreshChatList,
      (_) => _refreshConversations(),
    );
    
    // 监听新消息
    _newMessageWorker = ever(
      _globalCtrl.newMessage,
      (message) {
        if (message != null) {
          _handleNewMessage(message);
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshWorker?.dispose();
    _newMessageWorker?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// 处理新消息，更新会话列表和本地数据库
  void _handleNewMessage(Map<String, dynamic> message) {
    final convId = message['conversation_id']?.toString() ?? '';
    final content = message['content'] as String? ?? '';
    final sendTime = message['send_time'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final convType = message['conv_type'] as int? ?? 0;
    final from = message['from'] as String? ?? '';
    final nick = message['nick'] as String? ?? '';
    final msgType = message['m_type'] as int? ?? 0;
    
    if (convId.isEmpty) return;
    
    final userId = _currentUserId;
    if (userId.isEmpty) return;
    
    // 先计算更新后的会话，再更新UI
    ConversationModel updatedConv;
    
    // 查找现有会话
    final index = _conversations.indexWhere((c) => c.convId == convId);
    
    if (index != -1) {
      // 更新现有会话
      final oldConv = _conversations[index];
      updatedConv = oldConv.copyWith(
        lastMessage: content,
        lastMessageType: msgType,
        lastMessageTime: DateTime.fromMillisecondsSinceEpoch(sendTime),
        lastSenderId: from,
        lastSenderName: nick,
        unreadCount: oldConv.unreadCount + 1,
      );
    } else {
      // 创建新会话
      updatedConv = ConversationModel(
        convId: convId,
        displayName: nick.isNotEmpty ? nick : from,
        lastMessage: content,
        lastMessageType: msgType,
        lastMessageTime: DateTime.fromMillisecondsSinceEpoch(sendTime),
        lastSenderId: from,
        lastSenderName: nick,
        unreadCount: 1,
        convType: convType,
        targetId: from,
      );
    }
    
    setState(() {
      if (index != -1) {
        // 移除旧位置
        _conversations.removeAt(index);
      }
      
      // 插入到正确位置（置顶的放前面）
      if (updatedConv.isPinned) {
        _conversations.insert(0, updatedConv);
      } else {
        // 找到第一个非置顶会话的位置
        final firstNotPinned = _conversations.indexWhere((c) => !c.isPinned);
        if (firstNotPinned == -1) {
          _conversations.add(updatedConv);
        } else {
          _conversations.insert(firstNotPinned, updatedConv);
        }
      }
      
      // 重新过滤
      _filterConversations();
    });
    
    // 同步更新本地数据库
    _syncConversationToDatabase(userId, updatedConv);
  }
  
  /// 同步会话到本地数据库
  Future<void> _syncConversationToDatabase(String userId, ConversationModel conversation) async {
    try {
      await _messageDatabase.upsertConversation(userId, conversation);
      print('💾 会话已同步到本地: ${conversation.convId}');
    } catch (e) {
      print('❌ 同步会话到本地失败: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreConversations();
    }
  }

  /// 加载会话列表（先本地，后网络）
  Future<void> _loadConversations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    final userId = _currentUserId;
    if (userId.isEmpty) {
      print('⚠️ 用户未登录，无法加载会话列表');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. 先从本地数据库加载（快速显示）
      await _loadLocalConversations(userId);
      
      // 2. 再从网络加载
      await _loadNetworkConversations(userId);
      
    } catch (e) {
      print('❌ 加载会话列表错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 从本地数据库加载会话列表
  Future<void> _loadLocalConversations(String userId) async {
    try {
      print('📦 从本地数据库加载会话列表...');
      final localConversations = await _messageDatabase.getConversations(userId);
      
      if (localConversations.isNotEmpty) {
        print('📦 本地会话数: ${localConversations.length}');
        
        // 补充消息表中的最后一条消息
        final enrichedConversations = await _enrichConversationsWithLatestMessages(localConversations);
        
        setState(() {
          _conversations = enrichedConversations;
          _filterConversations();
        });
        
        // 更新全局未读数
        final totalUnread = await _messageDatabase.getTotalUnreadCount(userId);
        _globalCtrl.unreadCount.value = totalUnread;
      }
    } catch (e) {
      print('❌ 加载本地会话列表错误: $e');
    }
  }
  
  /// 从消息表补充会话的最后一条消息
  Future<List<ConversationModel>> _enrichConversationsWithLatestMessages(
    List<ConversationModel> conversations,
  ) async {
    final List<ConversationModel> enriched = [];
    
    for (final conv in conversations) {
      // 如果会话表中已有最后消息，直接使用
      if (conv.lastMessage?.isNotEmpty == true) {
        enriched.add(conv);
        continue;
      }
      
      // 从消息表获取最后一条消息
      final latestMessage = await _messageDatabase.getLatestMessage(conv.convId);
      
      if (latestMessage != null) {
        final enrichedConv = conv.copyWith(
          lastMessage: latestMessage.displayContent,
          lastMessageType: latestMessage.type.value,
          lastMessageTime: DateTime.fromMillisecondsSinceEpoch(latestMessage.createdAt),
          lastSenderId: latestMessage.senderId,
        );
        enriched.add(enrichedConv);
      } else {
        enriched.add(conv);
      }
    }
    
    return enriched;
  }
  
  /// 从网络加载会话列表
  Future<void> _loadNetworkConversations(String userId) async {
    if (_isLoadingFromNetwork) return;
    _isLoadingFromNetwork = true;
    
    try {
      print('🌐 从网络加载会话列表...');
      final result = await _nativeService.imGetConversationList(
        page: 1,
        pageSize: 20,
      );

      print('📋 网络会话列表结果: $result');

      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            final conversations = dataMap['conversations'] as List<dynamic>?;
            if (conversations != null) {
              final networkConversations = conversations
                  .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              
              // 合并本地和网络数据
              final mergedConversations = await _mergeConversations(
                userId,
                networkConversations,
              );
              
              setState(() {
                _conversations = mergedConversations;
                _hasMore = conversations.length >= 20;
                _filterConversations();
              });
              
              // 保存到本地数据库
              await _messageDatabase.upsertConversations(userId, mergedConversations);
              print('💾 已保存 ${mergedConversations.length} 个会话到本地');
              
              // 更新全局未读数
              final totalUnread = mergedConversations.fold<int>(
                0, (sum, conv) => sum + conv.unreadCount);
              _globalCtrl.unreadCount.value = totalUnread;
            }
          } catch (e) {
            print('❌ 解析会话列表失败: $e');
          }
        }
      } else {
        print('⚠️ 网络获取会话列表失败，使用本地数据');
        // 网络失败时，保持使用本地数据
      }
    } catch (e) {
      print('❌ 网络加载会话列表错误: $e');
    } finally {
      _isLoadingFromNetwork = false;
    }
  }
  
  /// 合并本地和网络会话数据
  /// 网络数据为主，本地数据补充缺失信息
  /// 最后一条消息：优先网络 → 会话表 → 消息表
  Future<List<ConversationModel>> _mergeConversations(
    String userId,
    List<ConversationModel> networkConversations,
  ) async {
    final List<ConversationModel> merged = [];
    
    for (final netConv in networkConversations) {
      // 1. 查询本地会话表
      final localConv = await _messageDatabase.getConversation(userId, netConv.convId);
      
      // 2. 查询消息表中该会话的最后一条消息
      final latestMessage = await _messageDatabase.getLatestMessage(netConv.convId);
      
      // 3. 确定最后一条消息（优先级：网络 > 会话表 > 消息表）
      String? finalLastMessage = netConv.lastMessage;
      int? finalLastMessageType = netConv.lastMessageType;
      DateTime? finalLastMessageTime = netConv.lastMessageTime;
      String? finalLastSenderId = netConv.lastSenderId;
      String? finalLastSenderName = netConv.lastSenderName;
      
      // 如果网络没有最后消息，尝试从本地会话表获取
      if (finalLastMessage == null || finalLastMessage.isEmpty) {
        if (localConv != null && localConv.lastMessage?.isNotEmpty == true) {
          finalLastMessage = localConv.lastMessage;
          finalLastMessageType = localConv.lastMessageType;
          finalLastMessageTime = localConv.lastMessageTime;
          finalLastSenderId = localConv.lastSenderId;
          finalLastSenderName = localConv.lastSenderName;
        }
      }
      
      // 如果还是没有，从消息表获取
      if (finalLastMessage == null || finalLastMessage.isEmpty) {
        if (latestMessage != null) {
          finalLastMessage = latestMessage.displayContent;
          finalLastMessageType = latestMessage.type.value;
          finalLastMessageTime = DateTime.fromMillisecondsSinceEpoch(latestMessage.createdAt);
          finalLastSenderId = latestMessage.senderId;
          // 发送者名称需要额外查询，暂时留空
        }
      }
      
      // 4. 合并数据
      final mergedConv = netConv.copyWith(
        // 未读数：网络优先，本地补充
        unreadCount: netConv.unreadCount > 0 ? netConv.unreadCount : (localConv?.unreadCount ?? 0),
        // 最后消息
        lastMessage: finalLastMessage,
        lastMessageType: finalLastMessageType ?? 0,
        lastMessageTime: finalLastMessageTime,
        lastSenderId: finalLastSenderId,
        lastSenderName: finalLastSenderName,
        // 保留本地的置顶、静音、草稿状态
        isPinned: localConv?.isPinned ?? false,
        isMuted: localConv?.isMuted ?? false,
        draft: localConv?.draft,
        // @我的数量
        atMeCount: netConv.atMeCount > 0 ? netConv.atMeCount : (localConv?.atMeCount ?? 0),
      );
      merged.add(mergedConv);
    }
    
    // 按置顶优先、时间倒序排序
    merged.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final timeA = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      final timeB = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
      return timeB.compareTo(timeA);
    });
    
    return merged;
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

  /// 刷新会话列表（带超时控制）
  /// 刷新会话列表（带超时控制）
  Future<void> _refreshConversations() async {
    // 重置分页
    _currentPage = 1;
    _hasMore = true;
    
    final userId = _currentUserId;
    if (userId.isEmpty) {
      EasyLoading.showError('用户未登录');
      return;
    }
    
    try {
      // 设置30秒超时
      final result = await _nativeService.imGetConversationList(
        page: 1,
        pageSize: 20,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ 刷新会话列表超时');
          return {'errorCode': -408, 'message': '请求超时'};
        },
      );

      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            final conversations = dataMap['conversations'] as List<dynamic>?;
            if (conversations != null) {
              final networkConversations = conversations
                  .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              
              // 合并本地和网络数据
              final mergedConversations = await _mergeConversations(
                userId,
                networkConversations,
              );
              
              setState(() {
                _conversations = mergedConversations;
                _hasMore = conversations.length >= 20;
                _filterConversations();
              });
              
              // 保存到本地数据库
              await _messageDatabase.upsertConversations(userId, mergedConversations);
              
              // 更新全局未读数
              final totalUnread = mergedConversations.fold<int>(
                0, (sum, conv) => sum + conv.unreadCount);
              _globalCtrl.unreadCount.value = totalUnread;
            }
          } catch (e) {
            print('解析会话列表失败: $e');
          }
        }
        
        // 刷新成功提示
        EasyLoading.showSuccess('刷新成功', duration: const Duration(seconds: 1));
      } else if (result['errorCode'] == -408) {
        // 超时，恢复页面状态
        EasyLoading.showError('刷新超时，请稍后重试');
        setState(() {});  // 恢复页面状态
      } else {
        EasyLoading.showError('刷新失败');
      }
    } catch (e) {
      print('刷新会话列表错误: $e');
      EasyLoading.showError('刷新失败');
      setState(() {});  // 恢复页面状态
    }
  }

  /// 过滤会话
  void _filterConversations() {
    final keyword = _searchController.text.trim().toLowerCase();
    
    // 先按类型筛选
    List<ConversationModel> filtered;
    switch (_filterType) {
      case 1: // 未读
        filtered = _conversations.where((conv) => conv.unreadCount > 0).toList();
        break;
      case 2: // 群聊
        filtered = _conversations.where((conv) => conv.convType == 2).toList();
        break;
      case 3: // @我的
        // TODO: 需要后端支持 at_me 字段
        filtered = _conversations.where((conv) => false).toList();
        break;
      default: // 全部
        filtered = List.from(_conversations);
    }
    
    // 再按关键词过滤
    if (keyword.isNotEmpty) {
      filtered = filtered
          .where((conv) =>
              conv.displayName.toLowerCase().contains(keyword) ||
              (conv.lastMessage?.toLowerCase().contains(keyword) ?? false))
          .toList();
    }
    
    _filteredConversations = filtered;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // 筛选栏
          _buildFilterBar(),
          // 会话列表
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildFilterButton(0, '全部', _getAllUnreadCount()),
          _buildFilterButton(1, '未读', _getAllUnreadCount()),  // 和全部一样显示总未读数
          _buildFilterButton(2, '群聊', _getGroupUnreadCount()),
          _buildFilterButton(3, '@我的', _getAtMeCount()),
        ],
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButton(int type, String label, int count) {
    final isSelected = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = type;
          });
          _filterConversations();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: Colors.blue, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 获取所有未读消息数
  int _getAllUnreadCount() {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// 获取未读会话数
  int _getUnreadConversationCount() {
    return _conversations.where((conv) => conv.unreadCount > 0).length;
  }

  /// 获取群聊未读消息数
  int _getGroupUnreadCount() {
    return _conversations
        .where((conv) => conv.convType == 2)
        .fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// 获取@我的未读数（需要后端支持，暂时返回0）
  int _getAtMeCount() {
    // TODO: 需要后端返回 at_me_count 字段
    return 0;
  }

  /// 构建普通 AppBar
  PreferredSizeWidget _buildNormalAppBar() {
    final globalController = Get.find<GlobalController>();
    final user = globalController.currentUser.value;
    final avatar = user?.avatar;
    final nickname = user?.nickname ?? '我';
    
    return AppBar(
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () {
            // 点击头像打开侧边栏菜单
            showSideMenu(context);
          },
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    nickname.isNotEmpty ? nickname.substring(0, 1) : '我',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ),
      title: const Text('聊天'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _openSearchPage,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showNewChatOptions,
        ),
      ],
    );
  }

  /// 构建搜索 AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchMode = false;
            _searchController.clear();
            _filterConversations();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索会话',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
        ),
        onChanged: (value) => _filterConversations(),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              _filterConversations();
            },
          ),
      ],
    );
  }

  /// 构建会话列表
  Widget _buildConversationList() {
    if (_isLoading && _conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 使用 RefreshIndicator 包裹整个内容，支持空状态下拉刷新
    return RefreshIndicator(
      onRefresh: _refreshConversations,
      color: Colors.blue,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.5,
      child: _filteredConversations.isEmpty
          ? _buildEmptyViewScrollable()
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // 确保始终可以下拉
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

  /// 构建可滚动的空视图（支持下拉刷新）
  Widget _buildEmptyViewScrollable() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyView(),
        ),
      ],
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
            // 头像（带未读数角标）
            Stack(
              clipBehavior: Clip.none,
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
                // 未读数角标
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // 在线状态指示器
                if (conversation.convType == 0 && conversation.isOnline && conversation.unreadCount == 0)
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
                  // 最后一条消息
                  Text(
                    conversation.lastMessage ?? '暂无消息',
                    style: TextStyle(
                      fontSize: 14,
                      color: conversation.unreadCount > 0 
                          ? Colors.black87  // 有未读消息时文字加深
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  void _openChat(ConversationModel conversation) async {
    // 跳转到聊天详情页
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          convId: conversation.convId,
          displayName: conversation.displayName,
          avatar: conversation.avatar,
          targetUserId: conversation.targetId ?? '',
        ),
      ),
    );
    
    // 返回后清除该会话的未读数
    _clearConversationUnread(conversation.convId);
  }
  
  /// 清除会话未读数
  void _clearConversationUnread(String convId) {
    final userId = _currentUserId;
    
    setState(() {
      final index = _conversations.indexWhere((c) => c.convId == convId);
      if (index != -1) {
        final oldConv = _conversations[index];
        if (oldConv.unreadCount > 0) {
          // 更新全局未读数
          _globalCtrl.unreadCount.value -= oldConv.unreadCount;
          if (_globalCtrl.unreadCount.value < 0) {
            _globalCtrl.unreadCount.value = 0;
          }
          // 清除该会话未读数
          _conversations[index] = oldConv.copyWith(unreadCount: 0);
          _filterConversations();
          
          // 同步到本地数据库
          if (userId.isNotEmpty) {
            _messageDatabase.clearConversationUnreadCount(userId, convId);
          }
        }
      }
    });
    
    // 调用后端接口标记已读
    _nativeService.imMarkConversationRead(convId: convId);
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

  /// 打开搜索页面
  void _openSearchPage() {
    Get.to(() => ChatSearchPage(conversations: _conversations));
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
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );
                // 如果创建成功，刷新会话列表
                if (result == true) {
                  _refreshConversations();
                }
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

