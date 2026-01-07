import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/controllers/user_controller.dart';
import 'package:bell_bird_talk/pages/community/pages/community_search_page.dart';
import 'package:bell_bird_talk/pages/profile/side_menu_page.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../models/community_model.dart';
import 'community_detail_page.dart';

/// 社群列表页面
class CommunityHomeUnjoinPage extends StatefulWidget {
  const CommunityHomeUnjoinPage({super.key});

  @override
  State<CommunityHomeUnjoinPage> createState() => _CommunityHomeUnjoinPageState();
}

class _CommunityHomeUnjoinPageState extends State<CommunityHomeUnjoinPage> {
  final List<CommunityModel> _communities = [];
  final List<CommunityModel> _filteredCommunities = [];
  String _selectedCategory = '全部';

  final MessageDatabase _messageDatabase = MessageDatabase();
  final IOSNativeService _nativeService = IOSNativeService();

  @override
  void initState() {
    super.initState();
    _loadDefaultCommunities();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  /// 加载默认社群
  void _loadDefaultCommunities() {
    setState(() {
      _communities.clear();
      _communities.addAll([
        CommunityModel(
          id: '1',
          name: '足球俱乐部',
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
      
      ]);
      _filteredCommunities.addAll(_communities);
    });
  }
  
  /// 筛选社群
  void _filterCommunities() {
    setState(() {
      _filteredCommunities.clear();
      _filteredCommunities.addAll(_communities.where((community) {
        final matchCategory = _selectedCategory == '全部' || community.category == _selectedCategory;
        return matchCategory;
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

    final result = await _nativeService.showNativeAlert(
      title: '申请加入社群',
      message: '社群将会给你发消息',
      confirmText: '确认',
      cancelText: '取消',
      showCancel: true,
    );
    bool confirmed = result != null && result['action'] == 'confirm';
    

    
    if (confirmed == true) {
      EasyLoading.show(status: '正在申请...');
      
      // 模拟申请过程
      await Future.delayed(const Duration(seconds: 1));
      GlobalController.to.joinedCommunitys = [community,CommunityModel(
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
        ),];
              GlobalController.to.updatecommunityTabRefresh();
      
      // 更新状态
      if (mounted) {
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
      }
      
      EasyLoading.dismiss();
      EasyLoading.showSuccess('申请已提交，请等待审核');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: _buildNormalAppBar(),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunitySearchPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '搜索',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
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

  

  Widget _userHeadImgView(String avatar, String nickname, String userId) {
    return FutureBuilder(
      future: UserController.to.fetchUserAvatarUrl(userId),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GbsColors.lightDivider,
          width: 0.5,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.1),
        //     spreadRadius: 1,
        //     blurRadius: 5,
        //     offset: const Offset(0, 2), // changes position of shadow
        //   ),
        // ],
      ),
      // elevation: 1,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(12),
      // ),
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
 
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称和分类
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 头像
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(right: 16),
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
                        Text(
                            community.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: GbsColors.des1Color
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                      ],
                    ),
                    
           
                    // 描述
                    Padding(padding: EdgeInsetsGeometry.only(top: 16, bottom: 16), child: Text(
                      community.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: GbsColors.des6Color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),),
                    
          
                    // 成员数和操作按钮
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 32),child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                         decoration: BoxDecoration(
                            color: GbsColors.lightPrimaryButton,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          '10000在线',
                          style: TextStyle(
                            fontSize: 12,
                            color: GbsColors.lightPrimaryButton,
                          ),
                        ),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                         decoration: BoxDecoration(
                            color: GbsColors.des9Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          '30000成员',
                          style: TextStyle(
                            fontSize: 12,
                            color: GbsColors.des9Color,
                          ),
                        )
                      ],
                    ),),
                    CommonButton(
                      enabled: true,
                      text: '加入社群', onPressed: () {
                      _applyToJoin(community);
                    }, fontSize: 16,),
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

