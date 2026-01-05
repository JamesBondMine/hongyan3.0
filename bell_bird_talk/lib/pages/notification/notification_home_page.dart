import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/noti_controller.dart';
import 'notification_child_page.dart';

class NotificationHomePage extends StatefulWidget {
  const NotificationHomePage({super.key});

  @override
  State<NotificationHomePage> createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(initialPage: NotiController.to.selectedTab);
    _currentIndex = NotiController.to.selectedTab;
    
    // 监听 Tab 切换
    _tabController.addListener(() {
      _currentIndex = _tabController.index;
        _pageController.jumpToPage( _tabController.index) ;
    });
    
    // 初始化加载数据
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 刷新数据
  Future<void> _refresh() async {
    await Future.wait([
      NotiController.to.loadUnread(),
    ]);
    NotiController.to.loading = false;
    NotiController.to.updateNotificationBar();
  }

  /// 处理页面滑动
  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: GetBuilder<NotiController>(
            id: NotiController.to.notificationBarRefreshId,
            builder: (controller) {
              return Container(
                height: 52,
                width: Get.width,
                // color: Colors.red,
                padding: EdgeInsets.only(right: Get.width - 260),
                margin: const EdgeInsets.only(left: 16),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorColor: GbsColors.primaryColor,
                  indicatorWeight: 2,
                  labelColor: GbsColors.primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: '全部'),
                    Tab(text: '未读'),
                    Tab(text: '已读'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: 3,
        itemBuilder: (context, index) {
          return NotificationChildPage(statusIndex: index);
        },
      ),
    );
  }
}
