import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/pages/profile/side_menu_page.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import '../models/community_model.dart';
import 'community_detail_page.dart';

/// 社群列表页面
class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({super.key});

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  final List<CommunityModel> _communities = [];
  final List<CommunityModel> _filteredCommunities = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '全部';

  final IOSNativeService _nativeService = IOSNativeService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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

      _filteredCommunities.addAll(
        _communities.where((community) {
          final matchCategory =
              _selectedCategory == '全部' ||
              community.category == _selectedCategory;
          final matchSearch =
              query.isEmpty ||
              community.name.toLowerCase().contains(query) ||
              community.description.toLowerCase().contains(query);
          return matchCategory && matchSearch;
        }).toList(),
      );
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
      confirmText: '确认'.tr,
      cancelText: '取消'.tr,
      showCancel: true,
    );
    bool confirmed = result != null && result['action'] == 'confirm';
    if (confirmed == true) {
      EasyLoading.show(status: '正在申请...');

      // 模拟申请过程
      await Future.delayed(const Duration(seconds: 1));
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

      body: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                      child: Text(
                        '取消'.tr,
                        style: TextStyle(
                          color: GbsColors.des1Color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 社群列表
            Expanded(
              child: _filteredCommunities.isEmpty
                  ? Center(
                      child: EmptyView(message: '暂无社群',community: true,),
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
      ),
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
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
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
        border: Border.all(color: GbsColors.lightDivider, width: 0.5),
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
                            color: GbsColors.des1Color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // 描述
                    Padding(
                      padding: EdgeInsetsGeometry.only(top: 16, bottom: 16),
                      child: Text(
                        community.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: GbsColors.des6Color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 成员数和操作按钮
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 32),
                      child: Row(
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
                          ),
                        ],
                      ),
                    ),
                    CommonButton(
                      enabled: true,
                      text: '加入社群',
                      onPressed: () {
                        _applyToJoin(community);
                      },
                      fontSize: 16,
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
