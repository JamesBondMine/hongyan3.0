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
            
            // IM SDK 状态卡片
            _buildIMSDKStatusCard(globalCtrl),
            
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
      
      return GestureDetector(
        onTap: () => _showUserInfoDialog(Get.context!, globalCtrl),
        child: Container(
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
                    // 显示邮箱或手机号
                    if (user?.email != null && user!.email!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            user!.email!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else if (user?.phone != null && user!.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            user!.phone!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        user?.signature ?? '点击查看详情',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
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
        ),
      );
    });
  }
  
  /// 显示用户信息对话框
  void _showUserInfoDialog(BuildContext context, GlobalController globalCtrl) {
    final user = globalCtrl.currentUser.value;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像居中
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                    ? NetworkImage(user!.avatar!)
                    : null,
                child: (user?.avatar == null || user!.avatar!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.blue)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow(Icons.person, '昵称', user?.nickname ?? '未设置'),
            _buildInfoRow(Icons.badge, '用户名', user?.username ?? '未设置'),
            _buildInfoRow(Icons.fingerprint, 'ID', user?.id ?? '未知'),
            _buildInfoRow(Icons.email, '邮箱', user?.email ?? '未绑定'),
            _buildInfoRow(Icons.phone, '手机', user?.phone ?? '未绑定'),
            _buildInfoRow(Icons.wc, '性别', _getGenderText(user?.gender)),
            _buildInfoRow(Icons.edit, '签名', user?.signature ?? '未设置'),
            _buildInfoRow(Icons.access_time, '注册时间', 
              user?.createdAt?.toString().substring(0, 19) ?? '未知'),
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
  
  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取性别文本
  String _getGenderText(int? gender) {
    switch (gender) {
      case 1: return '男';
      case 2: return '女';
      default: return '未设置';
    }
  }

  /// 构建 IM SDK 状态卡片
  Widget _buildIMSDKStatusCard(GlobalController globalCtrl) {
    return Obx(() {
      final status = globalCtrl.imsdkStatus.value;
      final isInitialized = globalCtrl.isIMSDKInitialized.value;
      
      // 根据状态设置颜色和图标
      Color statusColor;
      IconData statusIcon;
      
      if (status.contains('运行中')) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (status.contains('初始化成功') || status.contains('启动成功')) {
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
      } else if (status.contains('失败') || status.contains('异常')) {
        statusColor = Colors.red;
        statusIcon = Icons.error;
      } else if (status.contains('模拟器')) {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
      } else {
        statusColor = Colors.grey;
        statusIcon = Icons.info;
      }
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 状态图标
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 状态信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IM SDK 状态',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // 重试按钮（如果初始化失败）
            if (!isInitialized && !status.contains('正在'))
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  // 重新初始化
                  await globalCtrl.initializeIMSDK();
                },
                tooltip: '重试',
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
        'icon': Icons.people_outline,
        'title': '好友',
        'color': Colors.green,
        'onTap': () => Get.toNamed('/friends'),
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
          icon: Icon(Icons.people_outline),
          label: '好友',
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
        switch (index) {
          case 0:
            // 消息 - 当前页面
            break;
          case 1:
            // 好友 - 跳转到好友列表
            Get.toNamed('/friends');
            break;
          case 2:
            // 发现
            EasyLoading.showInfo('发现功能开发中');
            break;
          case 3:
            // 我的
            EasyLoading.showInfo('个人中心开发中');
            break;
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

