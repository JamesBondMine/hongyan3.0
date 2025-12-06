import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 好友模型
class FriendModel {
  final String id;
  final String nickname;
  final String? avatar;
  final String? signature;
  final bool isOnline;
  
  FriendModel({
    required this.id,
    required this.nickname,
    this.avatar,
    this.signature,
    this.isOnline = false,
  });
}

/// 好友列表页面
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // 模拟好友列表数据
  final List<FriendModel> _friends = [
    FriendModel(
      id: '1',
      nickname: '张三',
      signature: '今天天气真好',
      isOnline: true,
    ),
    FriendModel(
      id: '2',
      nickname: '李四',
      signature: '努力工作中...',
      isOnline: false,
    ),
    FriendModel(
      id: '3',
      nickname: '王五',
      signature: '生活不止眼前的苟且',
      isOnline: true,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<FriendModel> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _filteredFriends = _friends;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends
            .where((friend) =>
                friend.nickname.toLowerCase().contains(query.toLowerCase()))
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
            child: _filteredFriends.isEmpty
                ? _buildEmptyView()
                : _buildFriendList(),
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
            '好友 ${_friends.length} 人',
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

  /// 好友列表
  Widget _buildFriendList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredFriends.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 76,
      ),
      itemBuilder: (context, index) {
        final friend = _filteredFriends[index];
        return _buildFriendItem(friend);
      },
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
              backgroundImage: friend.avatar != null
                  ? NetworkImage(friend.avatar!)
                  : null,
              child: friend.avatar == null
                  ? Text(
                      friend.nickname[0].toUpperCase(),
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
          friend.nickname,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: friend.signature != null
            ? Text(
                friend.signature!,
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
                EasyLoading.showInfo('发起聊天: ${friend.nickname}');
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
                child: Text(
                  friend.nickname[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                friend.nickname,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
              if (friend.signature != null) ...[
                const SizedBox(height: 12),
                Text(
                  friend.signature!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
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
                      EasyLoading.showInfo('发起聊天: ${friend.nickname}');
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
                  EasyLoading.showInfo('设置备注开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('加入黑名单'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('加入黑名单开发中');
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

  /// 确认删除好友
  void _confirmDeleteFriend(FriendModel friend) {
    Get.dialog(
      AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友「${friend.nickname}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _friends.removeWhere((f) => f.id == friend.id);
                _filterFriends(_searchController.text);
              });
              EasyLoading.showSuccess('已删除好友');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

