import 'dart:convert';
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/user_controller.dart';
import 'package:bell_bird_talk/pages/chat/create_group_page.dart';
import 'package:bell_bird_talk/pages/friends/add_friend_page.dart';
import 'package:bell_bird_talk/pages/friends/pages/add_friends_group_page.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_search_page.dart';
import 'package:bell_bird_talk/pages/friends/views/friends_list_page.dart';
import 'package:bell_bird_talk/pages/friends/friend_groups_page.dart';
import 'package:bell_bird_talk/pages/friends/views/group_list_page.dart';
import 'package:bell_bird_talk/pages/friends/group_settings_sheet.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/pages/profile/side_menu_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:get/get.dart';
import '../../../controllers/global_controller.dart';
import '../../../services/native_bridge.dart';
import '../../../services/message_database.dart';
import '../views/friend_requests_page.dart';

/// 好友列表页面
class FriendsHomePage extends StatefulWidget {
  const FriendsHomePage({super.key});

  @override
  State<FriendsHomePage> createState() => _FriendsHomePageState();
}

class _FriendsHomePageState extends State<FriendsHomePage> with SingleTickerProviderStateMixin {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();

  // 子页面刷新
  final GlobalKey<FriendGroupsPageState> _friendGroupsPageKey = GlobalKey();
  
  // 好友申请
  final List<FriendRequestModel> _friendRequests = [];
  int _groupRequestCount = 0;
  bool _isLoadingRequests = false;

  late TabController _tabController;

  Worker? _refreshFriendRequestsWorker;

  List<FriendGroup> _groups = [];

  String _selectedGroupId = '';

  String _friends = '';
  
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

  /// 显示分组设置
  void _showGroupSettings() {
    gbs.shower.showScreenViewCustom(context, Get.height-160, Container(
      padding: EdgeInsets.only( top: 0,bottom: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorA,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
       child: AddFriendGroupPage(onAddGroup: () { 
        _friendGroupsPageKey.currentState?.refresh();
        },),));
  }


   /// 显示移动到分组弹窗
  Future<void> _showMoveToGroupDialog() async {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupSettingsSheet(
        onAddGroup: (){
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          // 弹出创建分组
          _showGroupSettings();
        },
        onDeleteGroup: _deleteGroup,
        onUpdateGroup: (group) async {
          // 刷新好友分组
          _friendGroupsPageKey.currentState?.refresh();
        },
      ),
    );
  }

  
  /// 删除分组
  void _deleteGroup(FriendGroup group) async{
    if (group.isDefault) {
      EasyLoading.showError('默认分组不能删除');
      return;
    }

    final result = await _nativeService.showNativeAlert(
      title: '删除分组',
      message: '确定要删除「${group.name}」分组吗？',
      confirmText: '删除',
      cancelText: '取消',
      showCancel: true,
    );
    
    if (result != null && result['action'] == 'confirm') {
      // 用户点击了确定
      Get.back();
      _confirmDeleteGroup(group);
    }
  }

  Future<void> _confirmDeleteGroup(FriendGroup group) async {
    EasyLoading.show(status: '删除分组中...');
    try {
      final gid = int.tryParse(group.id) ?? 0;
      final result = await _nativeService.imDeleteContactGroup(groupId: gid);
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('分组已删除');
        if (_selectedGroupId == group.id) {
          _selectedGroupId = 'all';
        }
        // 刷新好友分组
        _friendGroupsPageKey.currentState?.refresh();
      } else {
        EasyLoading.showError(result['message'] ?? '删除失败');
      }
    } catch (e) {
      EasyLoading.showError('删除失败，请稍后重试');
    }
  }


  Future<void> _createGroup() async {
    gbs.shower.showScreenViewCustom(context, Get.height-150, Container(
      width: Get.width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
      ),
      child: CreateGroupPage(onCreate: () {
        // _refreshConversations(0);
      },),
    ));
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
      final result = await UserController.to.getFriendRequests(
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
              _buildSearchBar(),
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
              Container(
                height: 8,
                width: Get.width,
                color: Color(0xffF3F3F3),
              ),
              // Tab Bar
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(right: Get.width * 0.45),
                decoration: BoxDecoration(
                  // color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xffE9E9E9),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: GbsColors.lightPrimaryButton,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: GbsColors.lightPrimaryButton,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.only(left: 4, bottom: 0),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: '好友'),
                    Tab(text: '分组'),
                    Tab(text: '群聊'),
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
            children: [
              FriendsListPage(),
              FriendGroupsPage(
                key:  _friendGroupsPageKey,
                onSettingGroup: (){
                _showMoveToGroupDialog();
              }),
              GroupListPage(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 12),
      color: Colors.white,
      child: InkWell(
        onTap: (){
          Get.to(() => const FriendSearchPage(friends: [],));
        },
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
            SizedBox(
              width: 22,
              height: 22,
              child: Image.asset('assets/img/friend/friend_new.png', width: 22,height: 22,),
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
                  color: GbsColors.darkPrimaryButton,
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
            // Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

