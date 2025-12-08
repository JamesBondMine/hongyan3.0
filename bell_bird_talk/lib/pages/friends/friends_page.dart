import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

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
  
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    await _loadFriends(refresh: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('好友'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,  // 不显示返回按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Get.toNamed('/add-friend'),
            tooltip: '添加好友',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          
          // 好友数量统计
          _buildFriendCount(),
          
          // 好友列表
          Expanded(
            child: _isLoading && _friends.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshFriends,
                    child: _filteredFriends.isEmpty
                        ? _buildEmptyView()
                        : _buildFriendList(),
                  ),
          ),
        ],
      ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-friend'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterFriends,
        decoration: InputDecoration(
          hintText: '搜索好友',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterFriends('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  /// 好友数量统计
  Widget _buildFriendCount() {
    final onlineCount = _friends.where((f) => f.isOnline).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '好友 $_totalCount 人',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '在线 $onlineCount',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
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
        ),
      ],
    );
  }

  /// 好友列表
  Widget _buildFriendList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            _hasMore) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredFriends.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 76,
        ),
        itemBuilder: (context, index) {
          if (index == _filteredFriends.length) {
            // 加载更多指示器
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final friend = _filteredFriends[index];
          return _buildFriendItem(friend);
        },
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
  void _showFriendDetail(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                friend.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (friend.remark != null && friend.remark != friend.nickname)
                Text(
                  '昵称: ${friend.nickname}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: friend.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    friend.isOnline ? '在线' : '离线',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (friend.accountId != null && friend.accountId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'ID: ${friend.accountId}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.chat,
                    label: '发消息',
                    color: Colors.blue,
                    onTap: () {
                      Get.back();
                      EasyLoading.showInfo('发起聊天: ${friend.displayName}');
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: '视频通话',
                    color: Colors.green,
                    onTap: () {
                      Get.back();
                      EasyLoading.showInfo('视频通话开发中');
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.phone,
                    label: '语音通话',
                    color: Colors.orange,
                    onTap: () {
                      Get.back();
                      EasyLoading.showInfo('语音通话开发中');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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
