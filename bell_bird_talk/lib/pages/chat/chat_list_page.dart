import 'dart:convert';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/pages/chat/group_chat_page.dart';
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
      (_) => _refreshConversations(0),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNormalAppBar(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSearchBar(),
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
    try {
      // 1. 先从本地数据库加载（快速显示）
      await _loadLocalConversations(userId);
      
      // 2. 再从网络加载
      await _loadNetworkConversations(userId);
      
    } catch (e) {
      print('❌ 加载会话列表错误: $e');
    } finally {
      if (!mounted) {
        setState(() {
        _isLoading = false;
      });
      }
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
      List<Map<String, dynamic>> conversations = await ChatController.to.getConversationList(
        page: 1,
        pageSize: 20,
        convType: 0,
        isUnread: false,
        isAtMe: false,
      );
   
              final networkConversations = conversations
                  .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              
              // 调用原生更新会话接口，确保会话信息同步到 SDK
              // for (final conv in networkConversations) {
              //   _nativeService.imUpdateConversation(
              //     convId: conv.convId,
              //     displayName: conv.displayName,
              //     avatarUrl: conv.avatar,
              //   );
              // }
              
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
            
 
        

    } catch (e) {
      print('❌ 网络加载会话列表错误: $e');
    } finally {
      _isLoadingFromNetwork = false;
    }
  }
  
  /// 合并本地和网络会话数据
  /// 网络数据为主，本地数据补充缺失信息
  /// 最后一条消息：优先网络 → 会话表 → 消息表
  /// 单聊时：从好友表获取备注/昵称/头像（备注优先）
  Future<List<ConversationModel>> _mergeConversations(
    String userId,
    List<ConversationModel> networkConversations,
  ) async {
    final List<ConversationModel> merged = [];
    
    // 批量获取所有单聊会话的好友信息
    final singleChatTargetIds = networkConversations
        .where((c) => c.convType == 0 && c.targetId != null && c.targetId!.isNotEmpty) // 单聊且有目标ID
        .map((c) => c.targetId!)
        .toList();
    final contactsMap = await _messageDatabase.getContactsMap(userId, singleChatTargetIds);
    
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

      
      
      // 4. 从好友表获取显示名称和头像（仅单聊）
      String displayName = netConv.displayName;
      String avatar = netConv.avatar ?? '';
      
      if (netConv.convType == 0) { // 单聊
        final contact = contactsMap[netConv.targetId];
        if (contact != null) {
          // 备注优先 > 昵称 > 网络返回的名称
          final remark = contact['remark'] as String?;
          final nickname = contact['nickname'] as String?;
          final contactAvatar = contact['avatar'] as String?;
          
          if (remark != null && remark.isNotEmpty) {
            displayName = remark;
          } else if (nickname != null && nickname.isNotEmpty) {
            displayName = nickname;
          }
          
          // 头像：好友表优先
          if (contactAvatar != null && contactAvatar.isNotEmpty) {
            avatar = contactAvatar;
          }
        }
      }
      
      // 5. 合并数据
      final mergedConv = netConv.copyWith(
        // 显示名称和头像
        displayName: displayName,
        avatar: avatar,
        avatarBg: netConv.avatarBg,
        // 未读数：网络优先，本地补充
        unreadCount: netConv.unreadCount > 0 ? netConv.unreadCount : (localConv?.unreadCount ?? 0),
        // 最后消息
        lastMessage: finalLastMessage,
        lastMessageType: finalLastMessageType,
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
        convType: _filterType,
        isUnread: _filterType == 1||_filterType == 3 ? true : false,
        isAtMe: _filterType == 3 ? true : false,
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

  /// 加载未读会话列表
  Future<void> _loadUnreadConversations() async {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      EasyLoading.showError('用户未登录');
      return;
    }
    
    EasyLoading.show(status: '加载未读会话...');
    
    try {
      print('📋 加载未读会话列表...');
      final result = await _nativeService.imGetUnreadConversations(
        page: 1,
        pageSize: 50,
        convType: -1,
      );
      
      print('📋 未读会话列表结果: $result');
      
      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            final conversations = dataMap['conversations'] as List<dynamic>?;
            if (conversations != null) {
              final unreadConversations = conversations
                  .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
                  .toList();
              
              // 合并本地和网络数据
              final mergedConversations = await _mergeConversations(
                userId,
                unreadConversations,
              );
              
              // 更新本地数据库
              await _messageDatabase.upsertConversations(userId, mergedConversations);
              print('💾 已更新 ${mergedConversations.length} 个未读会话到本地数据库');
              
              // 更新会话列表（只显示未读会话）
              setState(() {
                _conversations = mergedConversations;
                _filterConversations(); // 这会根据 _filterType 过滤未读会话
              });
              
              // 更新全局未读数
              final totalUnread = mergedConversations.fold<int>(
                0, (sum, conv) => sum + conv.unreadCount);
              _globalCtrl.unreadCount.value = totalUnread;
              
              EasyLoading.showSuccess('加载成功');
            } else {
              // 没有未读会话
              setState(() {
                _conversations = [];
                _filterConversations();
              });
              EasyLoading.showSuccess('暂无未读会话');
            }
          } catch (e) {
            print('❌ 解析未读会话列表失败: $e');
            EasyLoading.showError('解析数据失败');
          }
        } else {
          // 没有未读会话
          setState(() {
            _conversations = [];
            _filterConversations();
          });
          EasyLoading.showSuccess('暂无未读会话');
        }
      } else {
        print('⚠️ 获取未读会话列表失败: ${result['message']}');
        EasyLoading.showError(result['message'] ?? '获取失败');
      }
    } catch (e) {
      print('❌ 加载未读会话列表错误: $e');
      EasyLoading.showError('加载失败，请稍后重试');
    }
  }

  /// 刷新会话列表（带超时控制）
  /// 刷新会话列表（带超时控制）
  Future<void> _refreshConversations(int convType, {bool isAtMe = false}) async {
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
        convType: convType,
        isUnread: _filterType == 1||_filterType == 3 ? true : false,
        isAtMe: _filterType == 3 ? true : false,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ 刷新会话列表超时');
          return {'errorCode': -408, 'message': '请求超时'};
        },
      );

      if (result['errorCode'] == 0) {
        final data = result['data'];
        print('💬 刷新. convType $convType  isAtMe $isAtMe.  会话列表结果:   $data');
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


  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 12),
      color: Colors.white,
      child: InkWell(
        onTap: _openSearchPage,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '搜索',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
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
          _buildFilterButton(2, '群聊', _getGroupUnreadCount(false)),
          _buildFilterButton(3, '@我的', _getGroupUnreadCount(true)),
        ],
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButton(int type, String label, int count) {
    final isSelected = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _filterType = type;
          });
          
          // 根据筛选类型执行不同的操作
          if (type == 1) {
            // 点击"未读"：调用未读会话接口
            await _loadUnreadConversations();
          } else if (type == 0) {
            // 点击"全部"：刷新会话列表（调用更新会话列表）
            await _refreshConversations(0);
          } else if (type == 2) {
            // 点击"全部"：刷新会话列表（调用更新会话列表）
            await _refreshConversations(2);
          } else if (type == 3) {
            // 点击"全部"：刷新会话列表（调用更新会话列表）
            await _refreshConversations(0, isAtMe: true);
          } else {
            // 其他筛选类型：仅本地过滤
          // _filterConversations();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            // border: isSelected
            //     ? Border.all(color: Colors.blue, width: 1)
            //     : null,
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


  /// 获取群聊未读消息数
  int _getGroupUnreadCount(bool isOnlyAtMe) {
    if (isOnlyAtMe) {
      return _conversations
          .where((conv) => conv.convType == 2)
          .fold(0, (sum, conv) => sum + conv.unreadCount);
    }
    return _conversations
        .where((conv) => conv.convType == 2)
        .fold(0, (sum, conv) => sum + conv.unreadCount);
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
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showNewChatOptions,
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
      onRefresh: () => _refreshConversations(0),
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
                _getAvatarWidget(conversation, conversation.convType, conversation.avatarBg ?? ''),
                // 未读数角标
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: conversation.disturb ? Colors.grey : Colors.red,
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
                        child: Row(children: [
                          Text(
                          conversation.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 免打扰图标
                      if (!conversation.disturb)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.notifications_off,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        ],),
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
                    conversation.lastMessageDisplay.isNotEmpty 
                        ? conversation.lastMessageDisplay 
                        :  '暂无消息',
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
  Widget _getAvatarWidget(ConversationModel conversation, int convType, String bg) {
    //avatar_bg
    print('背景色: $bg');
    String bgcolor = '';
    String txtcolorStr = '';
    if (bg.isNotEmpty && bg.contains(':')) {
      bgcolor = bg.split(':').first;
      txtcolorStr = bg.split(':').last;
      if (bgcolor.isNotEmpty && bgcolor.contains('&')) {
        bgcolor = bgcolor.split('&').first;
      }
    }

    Color bgColor = Colors.grey;
    switch (convType) {
      case 0:
        bgColor = bg.isEmpty ? Colors.blue : Color(int.parse(bgcolor.replaceFirst('#', '0xFF')));
      case 1:
        bgColor = bg.isEmpty ? Colors.green : Color(int.parse(bgcolor.replaceFirst('#', '0xFF')));
      case 2:
        bgColor = bg.isEmpty ? Colors.green : Color(int.parse(bgcolor.replaceFirst('#', '0xFF')));
      case 3:
        bgColor = bg.isEmpty ? Colors.orange : Color(int.parse(bgcolor.replaceFirst('#', '0xFF')));
      case 4:
        bgColor = Colors.purple;
      default:
        bgColor = Colors.grey;
    }

    Color txtColor = bg.isEmpty ? Colors.blue : Color(int.parse(txtcolorStr.replaceFirst('#', '0xFF')));
    return CircleAvatar(
                  radius: 24,
                  backgroundColor: bgColor,
                  backgroundImage: (conversation.avatar != null && conversation.avatar!.isNotEmpty)
                      ? NetworkImage(conversation.avatar!)
                      : null,
                  child: (conversation.avatar == null || conversation.avatar!.isEmpty)
                      ? Text(
                          _getAvatarText(conversation),
                          style: TextStyle(
                            color: txtColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                );
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
    if (conversation.convType==2) {
       await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatPage(convId: conversation.convId, groupId: conversation.targetId ?? '', groupName: conversation.displayName),

      ),
    );
    // 清空会话ID
    ChatController.to.conversationId = "";
    } else { // 跳转到聊天详情页
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
    );}
    // 清空会话ID
    ChatController.to.conversationId = "";
   
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
    _nativeService.imMarkConversationRead(convId: convId, msgIds: '');
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
                _markAsRead(conversation, '');
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
                  _refreshConversations(0);
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
  Future<void> _markAsRead(ConversationModel conversation, String msgIds) async {
    try {
      final result = await _nativeService.imMarkConversationRead(
        convId: conversation.convId,
        msgIds: msgIds
      );
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('已标记为已读');
        _refreshConversations(0);
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
          // 删除本地数据库的会话
          final userId = _currentUserId;
          if (userId.isNotEmpty) {
            await _messageDatabase.deleteConversation(userId, conversation.convId);
          }
          _refreshConversations(0);
        } else {
          EasyLoading.showError('删除失败');
        }
      } catch (e) {
        EasyLoading.showError('删除失败: $e');
      }
    }
  }
}

