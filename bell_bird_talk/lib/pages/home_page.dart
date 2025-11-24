import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/global_controller.dart';
import 'native_demo_page.dart';
import 'framework_test_page.dart';

/// 首页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalController globalCtrl = Get.find<GlobalController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('铃鸟聊天'),
        backgroundColor: Colors.blue,
        actions: [
          // 未读消息徽章
          Obx(() => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  EasyLoading.showInfo('消息通知');
                },
              ),
              if (globalCtrl.unreadCount.value > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${globalCtrl.unreadCount.value > 99 ? '99+' : globalCtrl.unreadCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )),
          
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context, globalCtrl),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            _buildUserCard(globalCtrl),
            
            const SizedBox(height: 16),
            
            // 功能网格
            _buildFunctionGrid(context),
            
            const SizedBox(height: 16),
            
            // 快速访问
            _buildQuickAccess(),
          ],
        ),
      ),
      
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard(GlobalController globalCtrl) {
    return Obx(() {
      final user = globalCtrl.currentUser.value;
      
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                  ? NetworkImage(user!.avatar!)
                  : null,
              child: (user?.avatar == null || user!.avatar!.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: Colors.blue)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nickname ?? '未知用户',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.signature ?? '这个人很懒，什么都没留下',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${user?.id ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 箭头
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ],
        ),
      );
    });
  }

  /// 构建功能网格
  Widget _buildFunctionGrid(BuildContext context) {
    final functions = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': '聊天消息',
        'color': Colors.blue,
        'onTap': () => EasyLoading.showInfo('聊天功能开发中'),
      },
      {
        'icon': Icons.contacts_outlined,
        'title': '通讯录',
        'color': Colors.green,
        'onTap': () => EasyLoading.showInfo('通讯录功能开发中'),
      },
      {
        'icon': Icons.person_outline,
        'title': '个人中心',
        'color': Colors.orange,
        'onTap': () => EasyLoading.showInfo('个人中心开发中'),
      },
      {
        'icon': Icons.build_outlined,
        'title': '框架测试',
        'color': Colors.purple,
        'onTap': () => Get.to(() => const FrameworkTestPage()),
      },
      {
        'icon': Icons.phone_iphone,
        'title': '原生功能',
        'color': Colors.teal,
        'onTap': () => Get.to(() => const NativeDemoPage()),
      },
      {
        'icon': Icons.settings_outlined,
        'title': '系统设置',
        'color': Colors.grey,
        'onTap': () => EasyLoading.showInfo('设置功能开发中'),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: functions.length,
        itemBuilder: (context, index) {
          final function = functions[index];
          return _buildFunctionCard(
            icon: function['icon'] as IconData,
            title: function['title'] as String,
            color: function['color'] as Color,
            onTap: function['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建快速访问
  Widget _buildQuickAccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速访问',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickItem(
            icon: Icons.history,
            title: '最近聊天',
            onTap: () => EasyLoading.showInfo('最近聊天'),
          ),
          _buildQuickItem(
            icon: Icons.favorite_outline,
            title: '我的收藏',
            onTap: () => EasyLoading.showInfo('我的收藏'),
          ),
          _buildQuickItem(
            icon: Icons.download_outlined,
            title: '下载管理',
            onTap: () => EasyLoading.showInfo('下载管理'),
          ),
        ],
      ),
    );
  }

  /// 构建快速访问项
  Widget _buildQuickItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: '消息',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts_outlined),
          label: '通讯录',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          label: '发现',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '我的',
        ),
      ],
      onTap: (index) {
        if (index != 0) {
          EasyLoading.showInfo('功能开发中');
        }
      },
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog(BuildContext context, GlobalController globalCtrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('深色模式'),
              trailing: Obx(() => Switch(
                value: globalCtrl.isDarkMode.value,
                onChanged: (value) => globalCtrl.toggleTheme(),
              )),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('通知设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                EasyLoading.showInfo('通知设置');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, globalCtrl);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示退出登录对话框
  void _showLogoutDialog(BuildContext context, GlobalController globalCtrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              EasyLoading.show(status: '退出中...');
              
              await globalCtrl.logout();
              
              EasyLoading.showSuccess('已退出登录');
              
              // 跳转到登录页
              Get.offAllNamed('/login');
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

