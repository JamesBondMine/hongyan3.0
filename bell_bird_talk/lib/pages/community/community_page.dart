import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/pages/profile/side_menu_page.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:get/get.dart';
import 'models/community_model.dart';
import 'community_detail_page.dart';

/// 社群列表页面
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final List<CommunityModel> _communities = [];
  final List<CommunityModel> _filteredCommunities = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '全部';

  final MessageDatabase _messageDatabase = MessageDatabase();
  
  // 默认社群数据
  final List<String> _categories = ['全部', '技术', '生活', '娱乐', '学习', '其他'];
  
  @override
  void initState() {
    super.initState();
    _loadDefaultCommunities();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  /// 加载默认社群
  void _loadDefaultCommunities() {
    setState(() {
      _communities.clear();
      _communities.addAll([
        CommunityModel(
          id: '1',
          name: 'Flutter 技术交流',
          description: '专注于 Flutter 开发技术分享，包括 Dart 语言、Widget 开发、性能优化等',
          avatar: null,
          memberCount: 1250,
          maxMembers: 2000,
          category: '技术',
          isPublic: true,
          ownerName: 'Flutter官方',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 30,
        ),
        CommunityModel(
          id: '2',
          name: '美食分享圈',
          description: '分享各地美食，交流烹饪心得，发现身边的美食小店',
          avatar: null,
          memberCount: 890,
          maxMembers: 1000,
          category: '生活',
          isPublic: true,
          ownerName: '美食达人',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 20,
        ),
        CommunityModel(
          id: '3',
          name: '电影爱好者',
          description: '一起讨论最新电影，分享观影感受，推荐好片',
          avatar: null,
          memberCount: 2100,
          maxMembers: 3000,
          category: '娱乐',
          isPublic: true,
          ownerName: '影评人',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 60,
        ),
        CommunityModel(
          id: '4',
          name: '读书会',
          description: '每月共读一本书，分享读书笔记，交流阅读心得',
          avatar: null,
          memberCount: 650,
          maxMembers: 1000,
          category: '学习',
          isPublic: true,
          ownerName: '书虫',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 15,
        ),
        CommunityModel(
          id: '5',
          name: '健身打卡群',
          description: '每天坚持运动，互相鼓励，一起变得更健康',
          avatar: null,
          memberCount: 450,
          maxMembers: 500,
          category: '生活',
          isPublic: true,
          ownerName: '健身教练',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 10,
        ),
        CommunityModel(
          id: '6',
          name: '摄影交流',
          description: '分享摄影作品，学习摄影技巧，交流拍摄心得',
          avatar: null,
          memberCount: 320,
          maxMembers: 500,
          category: '其他',
          isPublic: true,
          ownerName: '摄影师',
          createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400 * 5,
        ),
      ]);
      _filteredCommunities.addAll(_communities);
    });
  }
  
  /// 搜索文本变化
  void _onSearchChanged() {
    _filterCommunities();
  }
  
  /// 筛选社群
  void _filterCommunities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommunities.clear();
      _filteredCommunities.addAll(_communities.where((community) {
        final matchCategory = _selectedCategory == '全部' || community.category == _selectedCategory;
        final matchSearch = query.isEmpty || 
            community.name.toLowerCase().contains(query) ||
            community.description.toLowerCase().contains(query);
        return matchCategory && matchSearch;
      }).toList());
    });
  }
  
  /// 申请加入社群
  Future<void> _applyToJoin(CommunityModel community) async {
    if (community.isJoined) {
      EasyLoading.showInfo('您已加入该社群');
      return;
    }
    
    if (community.hasApplied) {
      EasyLoading.showInfo('您已申请加入，请等待审核');
      return;
    }
    
    if (community.isFull) {
      EasyLoading.showError('该社群已满员');
      return;
    }
    
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('申请加入 ${community.name}'),
        content: Text('确定要申请加入该社群吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      EasyLoading.show(status: '正在申请...');
      
      // 模拟申请过程
      await Future.delayed(const Duration(seconds: 1));
      
      // 更新状态
      setState(() {
        final index = _communities.indexWhere((c) => c.id == community.id);
        if (index != -1) {
          _communities[index] = CommunityModel(
            id: community.id,
            name: community.name,
            description: community.description,
            avatar: community.avatar,
            memberCount: community.memberCount,
            maxMembers: community.maxMembers,
            category: community.category,
            isPublic: community.isPublic,
            ownerId: community.ownerId,
            ownerName: community.ownerName,
            createTime: community.createTime,
            isJoined: false,
            hasApplied: true,
          );
        }
        _filterCommunities();
      });
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('申请已提交，请等待审核');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildNormalAppBar(),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // 分类筛选
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterCommunities();
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 社群列表
          Expanded(
            child: _filteredCommunities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无社群',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCommunities.length,
                    itemBuilder: (context, index) {
                      final community = _filteredCommunities[index];
                      return _buildCommunityCard(community);
                    },
                  ),
          ),
        ],
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
      title: const Text('社群'),
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
     
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

  // 显示侧边栏菜单
void showSideMenu(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final menuWidth = screenWidth * 0.85; // 3/4 屏幕宽度
  
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'SideMenu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const SideMenuContent(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}
  
  /// 构建社群卡片
  Widget _buildCommunityCard(CommunityModel community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailPage(community: community),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: community.avatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          community.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.group,
                              color: Colors.blue[700],
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.group,
                        color: Colors.blue[700],
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称和分类
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            community.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 描述
                    Text(
                      community.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 成员数和操作按钮
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          community.memberCountText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (community.isFull) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '已满',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (community.isJoined)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '已加入',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          )
                        else if (community.hasApplied)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '已申请',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _applyToJoin(community),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '申请加入',
                              style: TextStyle(fontSize: 12),
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
      ),
    );
  }
}

