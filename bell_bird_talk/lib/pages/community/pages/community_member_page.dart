import 'package:bell_bird_talk/pages/community/pages/cmt_member_child_list_page.dart';
import 'package:bell_bird_talk/pages/community/pages/cmt_member_child_request_page.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
class CommunityMemberPage extends StatefulWidget {
  final String? cmtyId; // 社群ID（可选，如果未提供则从全局获取）

  const CommunityMemberPage({super.key, this.cmtyId});

  @override
  State<StatefulWidget> createState() {
    return CommunityMemberPageState();
  }
}

class CommunityMemberPageState extends State<CommunityMemberPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);
    // 监听 Tab 切换
    _tabController.addListener(() {
      _currentIndex = _tabController.index;
      _pageController.jumpToPage(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(
        title: '社群成员',
        backgroundColor: GbsColors.lightBackgroundA,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            // labelColor: GbsColors.lightText,
            // unselectedLabelColor: GbsColors.lightText,
            // indicatorColor: GbsColors.lightText,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: '成员列表'),
              Tab(text: '待处理'),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: 2,

              itemBuilder: (c, index) {
                return index == 0
                    ? CmtMemberListPage(cmtyId: widget.cmtyId,)
                    : CmtMemberRequestsPage(type: RequestType.friend);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 处理页面滑动
  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _tabController.animateTo(index);
    }
  }

  /// 空状态视图
  Widget _buildEmptyView() {
    return Center(child: EmptyView(community: true));
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 36, top: 10),
      height: 0.8,
      color: GbsColors.lightDivider,
    );
  }

  // 卡片
  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundB,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
