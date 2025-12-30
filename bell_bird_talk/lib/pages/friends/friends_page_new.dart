import 'dart:convert';
import 'package:bell_bird_talk/pages/chat/create_group_page.dart';
import 'package:bell_bird_talk/pages/friends/add_friend_page.dart';
import 'package:bell_bird_talk/pages/friends/views/friends_list_page.dart';
import 'package:bell_bird_talk/pages/friends/friend_groups_page.dart';
import 'package:bell_bird_talk/pages/friends/views/group_list_page.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/pages/profile/side_menu_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:get/get.dart';
import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';
import '../../services/message_database.dart';
import 'views/friend_requests_page.dart';

/// 好友列表页面
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  
  // 好友申请
  final List<FriendRequestModel> _friendRequests = [];
  int _groupRequestCount = 0;
  bool _isLoadingRequests = false;

  late TabController _tabController;

  Worker? _refreshFriendRequestsWorker;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadFriendRequests();
    
    final globalCtrl = Get.find<GlobalController>();
    
    _refreshFriendRequestsWorker = ever(
      globalCtrl.refreshFriendRequests,
      (_) {
        _loadFriendRequests();
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshFriendRequestsWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildNormalAppBar(),
      body: _buildMainContent(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      GestureDetector(
        child: Container(
          width: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/img//chat/chatuseradd.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text('添加好友'),
            ],
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFriendPage(),
            ),
          );
        },
      ),
      GestureDetector(
        child: Container(
          alignment: Alignment.center,
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/img//chat/chataddchat.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text('创建群聊'),
            ],
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _createGroup();
        },
      ),
    ];
  }

  Future<void> _createGroup() async {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    final globalController = Get.find<GlobalController>();
    final user = globalController.currentUser.value;
    final avatar = user?.avatar;
    final nickname = user?.nickname ?? '我';
    String userId = user?.id ?? '';

    return AppBar(
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () {
            showSideMenu(context);
          },
          child: _userHeadImgView(avatar ?? '', nickname, userId),
        ),
      ),
      title: const Text('好友'),
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        CustomPopup(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildAppBarActions(),
          ),
          child: Image.asset('assets/img/chat/chatadd.png', width: 24, height: 24),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Future<String> _fetchUserAvatarUrl(String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    Map<String, dynamic>? res = await _messageDatabase.getUser(userId);
    String bg = res?['avatar_bg'] ?? '';
    return bg;
  }

  Widget _userHeadImgView(String avatar, String nickname, String userId) {
    return FutureBuilder(
      future: _fetchUserAvatarUrl(userId),
      builder: (context, AsyncSnapshot<String> snapshot) {
        String bg = '';
        if (snapshot.hasData && snapshot.data != null) {
          bg = snapshot.data as String;
        }
        String bgcolorStr = '';
        String txtcolorStr = '';
        if (bg.isNotEmpty && bg.contains(':')) {
          bgcolorStr = bg.split(':').first;
          txtcolorStr = bg.split(':').last;
          if (bgcolorStr.isNotEmpty && bgcolorStr.contains('&')) {
            bgcolorStr = bgcolorStr.split('&').first;
          }
        }

        Color bgColor = bg.isEmpty ? Colors.blue : Color(int.parse(bgcolorStr.replaceFirst('#', '0xFF')));
        Color txtColor = bg.isEmpty ? Colors.blue : Color(int.parse(txtcolorStr.replaceFirst('#', '0xFF')));

        return CircleAvatar(
          radius: 18,
          backgroundColor: bgColor,
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Text(
                  nickname.isNotEmpty ? nickname.substring(0, 1) : '我',
                  style: TextStyle(
                    color: txtColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _loadFriendRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() => _isLoadingRequests = true);
    
    try {
      final result = await _nativeService.imGetFriendRequests(
        status: 0,
        page: 1,
        pageSize: 1,
      );
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final requestsJson = data['requests'] as List? ?? [];
          
          final globalCtrl = Get.find<GlobalController>();
          final requestCount = data['total_count'] ?? 0;
          
          setState(() {
            _groupRequestCount = requestCount;
            _friendRequests.clear();
            _friendRequests.addAll(
              requestsJson.map((json) => FriendRequestModel.fromJson(json)).toList(),
            );
          });
          
          globalCtrl.groupRequestCount.value = requestCount;
        }
      }
    } catch (e) {
      print('❌ 获取好友申请失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 好友申请入口
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildRequestEntryItem(
                icon: Icons.person_add,
                iconColor: Colors.orange,
                iconBgColor: Colors.orange[50]!,
                title: '新的朋友',
                count: _groupRequestCount,
                onTap: () async {
                  final result = await Get.to(() => const FriendRequestsPage(type: RequestType.friend));
                  if (result == true) {
                    _loadFriendRequests();
                  }
                },
              ),
              // Tab Bar
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: '好友'),
                    Tab(text: '分组'),
                    Tab(text: '群组'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tab View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              FriendsListPage(),
              FriendGroupsPage(),
              GroupListPage(),
            ],
          ),
        ),
      ],
    );
  }

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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

