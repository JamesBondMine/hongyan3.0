import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';
import 'friend_detail_page.dart';
import 'friend_requests_page.dart';

/// 好友模型
class FriendModel {
  final String id;
  final String? accountId;
  final String nickname;
  final String? avatar;
  final String? remark;
  final int relationship;  // 0=好友, 1=黑名单等
  final int onlineStatus;  // 0=离线, 1=在线
  
  FriendModel({
    required this.id,
    this.accountId,
    required this.nickname,
    this.avatar,
    this.remark,
    this.relationship = 0,
    this.onlineStatus = 0,
  });
  
  /// 从 JSON 构造
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['contact_user_id'] ?? json['user_id'] ?? '',
      accountId: json['account_id'],
      nickname: json['nickname'] ?? json['remark'] ?? '未知用户',
      avatar: json['avatar'],
      remark: json['remark'],
      relationship: json['relationship'] ?? 0,
      onlineStatus: json['online_status'] ?? 0,
    );
  }
  
  /// 是否在线
  bool get isOnline => onlineStatus == 1;
  
  /// 显示名称（优先显示备注）
  String get displayName => (remark != null && remark!.isNotEmpty) ? remark! : nickname;
}

/// 好友分组模型
class FriendGroup {
  final String id;
  final String name;
  final bool isDefault;  // 是否是默认分组（不可删除）
  int count;  // 分组内好友数量
  
  FriendGroup({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.count = 0,
  });
}

/// 好友申请模型
class FriendRequestModel {
  final int requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String? message;
  final int channel;
  final int status;  // 0=待处理, 1=已同意, 2=已拒绝
  final int requestTime;
  final int expireTime;
  
  FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    this.message,
    this.channel = 0,
    this.status = 0,
    this.requestTime = 0,
    this.expireTime = 0,
  });
  
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: json['request_id'] ?? 0,
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '未知用户',
      requesterAvatar: json['requester_avatar'],
      message: json['message'],
      channel: json['channel'] ?? 0,
      status: json['status'] ?? 0,
      requestTime: json['request_time'] ?? 0,
      expireTime: json['expire_time'] ?? 0,
    );
  }
  
  /// 是否待处理
  bool get isPending => status == 0;
  
  /// 格式化时间
  String get formattedTime {
    if (requestTime == 0) return '';
    final time = DateTime.fromMillisecondsSinceEpoch(requestTime);
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}

/// 好友列表页面
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _searchController = TextEditingController();
  
  final List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  
  // 好友申请
  final List<FriendRequestModel> _friendRequests = [];
  int _groupRequestCount = 0;  // 群组申请数量
  bool _isLoadingRequests = false;
  
  // 好友分组
  final List<FriendGroup> _groups = [
    FriendGroup(id: 'all', name: '全部', isDefault: true),
    FriendGroup(id: 'special', name: '特别关心', isDefault: true),
  ];
  String _selectedGroupId = 'all';  // 当前选中的分组
  
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();  // 先加载好友申请
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载好友申请列表
  Future<void> _loadFriendRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() => _isLoadingRequests = true);
    
    try {
      final result = await _nativeService.imGetFriendRequests(
        status: 0,  // 只获取待处理的
        page: 1,
        pageSize: 50,
      );
      
      print('📋 好友申请列表结果: $result');
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final requestsJson = data['requests'] as List? ?? [];
          
          setState(() {
            _friendRequests.clear();
            _friendRequests.addAll(
              requestsJson.map((json) => FriendRequestModel.fromJson(json)).toList(),
            );
          });
        }
      }
    } catch (e) {
      print('❌ 获取好友申请失败: $e');
    } finally {
      setState(() => _isLoadingRequests = false);
    }
  }

  /// 加载好友列表
  Future<void> _loadFriends({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoading = true);
    }
    
    try {
      final result = await _nativeService.imGetContactList(
        page: refresh ? 1 : _currentPage,
        pageSize: _pageSize,
      );
      
      print('📋 好友列表结果: $result');
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          
          _totalCount = data['total_count'] ?? 0;
          final contactsJson = data['contacts'] as List? ?? [];
          
          final newFriends = contactsJson
              .map((json) => FriendModel.fromJson(json))
              .toList();
          
          setState(() {
            if (refresh) {
              _friends.clear();
            }
            _friends.addAll(newFriends);
            _filteredFriends = List.from(_friends);
            _hasMore = newFriends.length >= _pageSize;
            if (!refresh) {
              _currentPage++;
            }
          });
          
          // 应用搜索过滤
          _filterFriends(_searchController.text);
        } else {
          setState(() {
            if (refresh) {
              _friends.clear();
              _filteredFriends.clear();
            }
            _hasMore = false;
          });
        }
      } else {
        final message = result['message'] ?? '获取失败';
        EasyLoading.showError(message);
      }
    } catch (e) {
      print('❌ 获取好友列表失败: $e');
      EasyLoading.showError('获取好友列表失败');
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// 刷新好友列表
  Future<void> _refreshFriends() async {
    await Future.wait([
      _loadFriendRequests(),
      _loadFriends(refresh: true),
    ]);
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      await _loadFriends();
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_friends);
      } else {
        _filteredFriends = _friends
            .where((friend) =>
                friend.displayName.toLowerCase().contains(query.toLowerCase()) ||
                (friend.accountId?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  // 是否显示搜索模式
  bool _isSearchMode = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isLoading && _friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFriends,
              child: _buildMainContent(),
            ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-friend'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  /// 主内容区域
  Widget _buildMainContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            _hasMore &&
            !_isLoading) {
          _loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // 新消息入口（好友申请、群组申请）
          SliverToBoxAdapter(child: _buildRequestsEntry()),
          
          // 好友分组
          SliverToBoxAdapter(child: _buildGroupTabs()),
          
          // 好友列表
          if (_filteredFriends.isEmpty)
            SliverFillRemaining(child: _buildEmptyView())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _filteredFriends.length) {
                    return _hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  return _buildFriendItem(_filteredFriends[index]);
                },
                childCount: _filteredFriends.length + (_hasMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }
  
  /// 新消息入口（好友申请、群组申请）
  Widget _buildRequestsEntry() {
    final friendCount = _friendRequests.where((r) => r.status == 0).length;
    
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 好友申请入口
          _buildRequestEntryItem(
            icon: Icons.person_add,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange[50]!,
            title: '好友申请',
            count: friendCount,
            onTap: () {
              Get.to(() => const FriendRequestsPage(type: RequestType.friend));
            },
          ),
          
          Divider(height: 1, indent: 56, color: Colors.grey[100]),
          
          // 群组申请入口
          _buildRequestEntryItem(
            icon: Icons.group_add,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue[50]!,
            title: '群组申请',
            count: _groupRequestCount,
            onTap: () {
              Get.to(() => const FriendRequestsPage(type: RequestType.group));
            },
          ),
        ],
      ),
    );
  }
  
  /// 申请入口项
  Widget _buildRequestEntryItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            
            // 标题
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // 数量角标
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
            
            // 箭头
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  /// 普通 AppBar
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('好友'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() => _isSearchMode = true);
          },
          tooltip: '搜索好友',
        ),
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          onPressed: () => Get.toNamed('/add-friend'),
          tooltip: '添加好友',
        ),
      ],
    );
  }
  
  /// 搜索模式 AppBar
  AppBar _buildSearchAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: false,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: '搜索好友',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _filterFriends('');
                  },
                )
              : null,
        ),
        onChanged: _filterFriends,
      ),
      actions: [
        TextButton(
          onPressed: () {
            _searchController.clear();
            _filterFriends('');
            setState(() => _isSearchMode = false);
          },
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// 好友数量统计
  /// 好友分组标签栏
  Widget _buildGroupTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 分组列表（横向滚动）
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  final isSelected = group.id == _selectedGroupId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildGroupChip(group, isSelected),
                  );
                },
              ),
            ),
          ),
          
          // 分组设置按钮
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _showGroupSettings,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 分组标签
  Widget _buildGroupChip(FriendGroup group, bool isSelected) {
    // 更新分组内的好友数量
    if (group.id == 'all') {
      group.count = _totalCount;
    } else if (group.id == 'special') {
      // TODO: 特别关心的筛选逻辑
      group.count = 0;
    }
    
    return GestureDetector(
      onTap: () => _selectGroup(group.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (group.count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${group.count}',
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 选择分组
  void _selectGroup(String groupId) {
    if (_selectedGroupId == groupId) return;
    
    setState(() {
      _selectedGroupId = groupId;
    });
    
    // 根据分组筛选好友
    _filterFriendsByGroup(groupId);
  }
  
  /// 根据分组筛选好友
  void _filterFriendsByGroup(String groupId) {
    setState(() {
      if (groupId == 'all') {
        // 全部好友
        _filteredFriends = List.from(_friends);
      } else if (groupId == 'special') {
        // 特别关心：TODO 根据实际标签筛选
        _filteredFriends = [];
      } else {
        // 自定义分组：TODO 根据分组ID筛选
        _filteredFriends = [];
      }
    });
    
    // 如果有搜索关键词，继续过滤
    if (_searchController.text.isNotEmpty) {
      _filterFriends(_searchController.text);
    }
  }
  
  /// 显示分组设置
  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GroupSettingsSheet(
        groups: _groups,
        onAddGroup: _addGroup,
        onDeleteGroup: _deleteGroup,
      ),
    );
  }
  
  /// 添加分组
  void _addGroup(String name) {
    if (name.isEmpty) {
      EasyLoading.showError('分组名称不能为空');
      return;
    }
    
    // 检查是否已存在
    if (_groups.any((g) => g.name == name)) {
      EasyLoading.showError('分组已存在');
      return;
    }
    
    setState(() {
      _groups.add(FriendGroup(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
      ));
    });
    
    EasyLoading.showSuccess('分组创建成功');
  }
  
  /// 删除分组
  void _deleteGroup(FriendGroup group) {
    if (group.isDefault) {
      EasyLoading.showError('默认分组不能删除');
      return;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除「${group.name}」分组吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _groups.removeWhere((g) => g.id == group.id);
                // 如果删除的是当前选中的分组，切回全部
                if (_selectedGroupId == group.id) {
                  _selectedGroupId = 'all';
                  _filterFriendsByGroup('all');
                }
              });
              EasyLoading.showSuccess('分组已删除');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? '暂无好友' : '未找到匹配的好友',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isEmpty)
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/add-friend'),
              icon: const Icon(Icons.person_add),
              label: const Text('添加好友'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 好友项
  Widget _buildFriendItem(FriendModel friend) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              backgroundImage: (friend.avatar != null && friend.avatar!.isNotEmpty)
                  ? NetworkImage(friend.avatar!)
                  : null,
              child: (friend.avatar == null || friend.avatar!.isEmpty)
                  ? Text(
                      friend.displayName.isNotEmpty 
                          ? friend.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            // 在线状态指示器
            if (friend.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: friend.accountId != null && friend.accountId!.isNotEmpty
            ? Text(
                'ID: ${friend.accountId}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.blue[400]),
              onPressed: () {
                EasyLoading.showInfo('发起聊天: ${friend.displayName}');
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onPressed: () => _showFriendOptions(friend),
            ),
          ],
        ),
        onTap: () => _showFriendDetail(friend),
      ),
    );
  }

  /// 显示好友详情
  void _showFriendDetail(FriendModel friend) async {
    final result = await Get.to(
      () => FriendDetailPage(friend: friend),
      transition: Transition.rightToLeft,
    );
    
    // 如果返回 true，刷新好友列表
    if (result == true) {
      _refreshFriends();
    }
  }

  /// 显示好友操作菜单
  void _showFriendOptions(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline, color: Colors.amber),
                title: const Text('设为星标好友'),
                onTap: () {
                  Get.back();
                  EasyLoading.showSuccess('已设为星标好友');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('设置备注'),
                onTap: () {
                  Get.back();
                  _showSetRemarkDialog(friend);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('加入黑名单'),
                onTap: () {
                  Get.back();
                  _confirmBlockFriend(friend);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除好友'),
                onTap: () {
                  Get.back();
                  _confirmDeleteFriend(friend);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 设置备注对话框
  void _showSetRemarkDialog(FriendModel friend) {
    final controller = TextEditingController(text: friend.remark);
    
    Get.dialog(
      AlertDialog(
        title: const Text('设置备注'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入备注名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: 调用设置备注接口
              EasyLoading.showSuccess('备注设置成功');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 确认拉黑好友
  void _confirmBlockFriend(FriendModel friend) {
    Get.dialog(
      AlertDialog(
        title: const Text('加入黑名单'),
        content: Text('确定要将「${friend.displayName}」加入黑名单吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              EasyLoading.show(status: '处理中...');
              
              try {
                final result = await _nativeService.imBlockContact(userId: friend.id);
                
                if (result['errorCode'] == 0) {
                  EasyLoading.showSuccess('已加入黑名单');
                  _refreshFriends();
                } else {
                  EasyLoading.showError(result['message'] ?? '操作失败');
                }
              } catch (e) {
                EasyLoading.showError('操作失败');
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  /// 确认删除好友
  void _confirmDeleteFriend(FriendModel friend) {
    Get.dialog(
      AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友「${friend.displayName}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              EasyLoading.show(status: '删除中...');
              
              try {
                final result = await _nativeService.imDeleteContact(userId: friend.id);
                
                if (result['errorCode'] == 0) {
                  setState(() {
                    _friends.removeWhere((f) => f.id == friend.id);
                    _filterFriends(_searchController.text);
                    _totalCount = _friends.length;
                  });
                  EasyLoading.showSuccess('已删除好友');
                } else {
                  EasyLoading.showError(result['message'] ?? '删除失败');
                }
              } catch (e) {
                EasyLoading.showError('删除失败');
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 分组设置底部弹窗
class _GroupSettingsSheet extends StatefulWidget {
  final List<FriendGroup> groups;
  final Function(String) onAddGroup;
  final Function(FriendGroup) onDeleteGroup;
  
  const _GroupSettingsSheet({
    required this.groups,
    required this.onAddGroup,
    required this.onDeleteGroup,
  });

  @override
  State<_GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends State<_GroupSettingsSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isAdding = false;  // 是否正在添加分组
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '分组管理',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAdding = !_isAdding;
                      if (!_isAdding) {
                        _nameController.clear();
                      }
                    });
                  },
                  icon: Icon(_isAdding ? Icons.close : Icons.add, size: 18),
                  label: Text(_isAdding ? '取消' : '新建分组'),
                ),
              ],
            ),
          ),
          
          // 新建分组输入框
          if (_isAdding)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '输入分组名称',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty) {
                        widget.onAddGroup(name);
                        setState(() {
                          _isAdding = false;
                          _nameController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('创建'),
                  ),
                ],
              ),
            ),
          
          const Divider(height: 1),
          
          // 分组列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.groups.length,
              itemBuilder: (context, index) {
                final group = widget.groups[index];
                return _buildGroupItem(group);
              },
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
  
  Widget _buildGroupItem(FriendGroup group) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: group.isDefault ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          group.id == 'special' ? Icons.star : Icons.folder,
          color: group.isDefault ? Colors.blue : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        group.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        group.isDefault ? '默认分组' : '${group.count} 位好友',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 13,
        ),
      ),
      trailing: group.isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '不可删除',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            )
          : IconButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDeleteGroup(group);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
    );
  }
}
