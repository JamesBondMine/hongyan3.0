import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/global_controller.dart';
import '../services/native_bridge.dart';
import 'native_demo_page.dart';
import 'framework_test_page.dart';
import 'friends/friends_page.dart';
import 'chat/chat_list_page.dart';
import 'profile/profile_page.dart';
import 'profile/profile_tab_page.dart';

/// 首页（带底部 TabBar）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final IOSNativeService _nativeService = IOSNativeService();
  
  // 上传凭证信息
  @override
  void initState() {
    super.initState();
    // 进入首页时注册消息回调
    _registerMessageCallbacks();
  }
  
  @override
  void dispose() {
    // 离开首页时取消注册
    _nativeService.imUnregisterMessageCallbacks();
    super.dispose();
  }
  
  /// 注册消息回调（单聊、群聊、社区、系统、命令）
  Future<void> _registerMessageCallbacks() async {
    // 设置消息接收回调
    _nativeService.onMessageReceived = _handleReceivedMessage;
    
    // 设置系统消息回调
    _nativeService.onSystemMessage = _handleSystemMessage;
    
    // 设置命令消息回调
    _nativeService.onCommandMessage = _handleCommandMessage;
    
    // 注册底层回调
    final result = await _nativeService.imRegisterMessageCallbacks();
    if (result['errorCode'] == 0) {
      print('✅ 消息回调注册成功（单聊、群聊、社区、系统、命令）');
    } else {
      print('❌ 消息回调注册失败: ${result['message']}');
    }
  }
  
  /// 处理收到的消息
  void _handleReceivedMessage(Map<String, dynamic> message) {
    print('📨 首页收到消息: $message');
    
    final convType = message['conv_type'] as int?;
    final content = message['content'] as String?;
    final from = message['from'] as String?;
    
    String convTypeStr = '未知';
    switch (convType) {
      case 0: convTypeStr = '单聊'; break;
      case 2: convTypeStr = '群聊'; break;
      case 4: convTypeStr = '社区'; break;
    }
    
    print('📨 [$convTypeStr] 来自 $from: $content');
    
    // 通知 GlobalController 更新聊天列表
    _globalCtrl.onNewMessageReceived(message);
  }
  
  /// 处理系统消息  被加好友  是系统消息
  void _handleSystemMessage(Map<String, dynamic> message) {
    print('📨 首页收到系统消息: $message');
    
    // 收到系统消息，刷新联系人列表和好友申请列表
    // 系统消息可能包括：好友申请、好友通过、好友删除等
    _globalCtrl.triggerContactRefresh();
    
    print('✅ 已触发联系人和好友申请列表刷新');
  }
  
  /// 处理命令消息
  void _handleCommandMessage(int eventType, Map<String, dynamic> message) {
    print('📨 首页收到命令消息: eventType=$eventType, data=$message');
    
    // TODO: 根据命令类型进行处理
    // 例如：强制更新、配置变更等
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: 聊天页面
          const ChatListPage(),
          // Tab 1: 好友页面
          const FriendsPage(),
          // Tab 2: 消息页面
          _buildMessagePage(),
          // Tab 3: 我的页面
          const ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 消息页面（原首页内容）
  Widget _buildMessagePage() {
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
              if (_globalCtrl.unreadCount.value > 0)
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
                      '${_globalCtrl.unreadCount.value > 99 ? '99+' : _globalCtrl.unreadCount.value}',
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
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            _buildUserCard(),
            
            const SizedBox(height: 16),
            
            // IM SDK 状态卡片
            _buildIMSDKStatusCard(),
            
            const SizedBox(height: 16),
            
            // 功能网格
            _buildFunctionGrid(context),
            
            const SizedBox(height: 16),
            
            // 快速访问
            _buildQuickAccess(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard() {
    return Obx(() {
      final user = _globalCtrl.currentUser.value;
      final avatar = user?.avatar ?? '';
      final email = user?.email ?? '';
      final phone = user?.phone ?? '';
      
      return GestureDetector(
        onTap: () => Get.to(() => const ProfilePage()),
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
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
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
                    if (email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else if (phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
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
  
  /// 构建 IM SDK 状态卡片
  Widget _buildIMSDKStatusCard() {
    return Obx(() {
      final status = _globalCtrl.imsdkStatus.value;
      final isInitialized = _globalCtrl.isIMSDKInitialized.value;
      
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
                  await _globalCtrl.initializeIMSDK();
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
        'onTap': () => setState(() => _currentIndex = 1),  // 切换到好友 Tab
      },
      {
        'icon': Icons.person_outline,
        'title': '个人中心',
        'color': Colors.orange,
        'onTap': () => setState(() => _currentIndex = 3),  // 切换到我的 Tab
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
        'onTap': () => _showSettingsDialog(context),
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
      currentIndex: _currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: '聊天',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: '好友',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '消息',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog(BuildContext context) {
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
                value: _globalCtrl.isDarkMode.value,
                onChanged: (value) => _globalCtrl.toggleTheme(),
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
                _showLogoutDialog(context);
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
  void _showLogoutDialog(BuildContext context) {
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
              _globalCtrl.logout();
              EasyLoading.dismiss();
              EasyLoading.showSuccess('已退出登录');
              await Future.delayed(const Duration(seconds: 1));
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
