import 'dart:convert';
import 'package:bell_bird_talk/pages/profile/profile_page.dart';
import 'package:bell_bird_talk/pages/settings/language_page.dart';
import 'package:bell_bird_talk/pages/settings/security_settings_page.dart';
import 'package:bell_bird_talk/pages/notification/notification_page.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';

/// 侧边栏菜单内容
class SideMenuContent extends StatefulWidget {
  const SideMenuContent({super.key});

  @override
  State<SideMenuContent> createState() => _SideMenuContentState();
}

class _SideMenuContentState extends State<SideMenuContent> {
  final IOSNativeService _nativeService = IOSNativeService();
  int _notificationUnread = 0;
  bool _fetchingUnread = false;
  final MessageDatabase _messageDatabase = MessageDatabase();
  
  @override
  void initState() {
    super.initState();
    _loadNotificationUnread();
  }

  Future<void> _loadNotificationUnread() async {
    if (_fetchingUnread) return;
    setState(() => _fetchingUnread = true);
    final result = await _nativeService.imGetNotificationUnreadCount(types: ['0']);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      try {
        if (dataStr.isNotEmpty) {
          final map = Map<String, dynamic>.from(jsonDecode(dataStr));
          final unread = (map['total_unread'] as num?)?.toInt() ?? 0;
          setState(() => _notificationUnread = unread);
        } else {
          setState(() => _notificationUnread = 0);
        }
      } catch (_) {
        // ignore parse errors
      }
    }
    if (mounted) setState(() => _fetchingUnread = false);
  }
  


  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    
    return Scaffold(
      body: Column(
        children: [
          // 用户信息头部
          _buildUserHeader(globalController),
          
          // 菜单列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: 'settingnoti',
                  title: '通知',
                  subtitle: _notificationUnread > 0 ? '未读 $_notificationUnread' : '消息提醒',
                  trailing: _notificationUnread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_notificationUnread',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () => _openNotificationSettings(context),
                ),
                _buildMenuItem(
                  icon: 'settingaccount',
                  title: '安全设置',
                  subtitle: '密码、隐私管理',
                  onTap: () => _openSecuritySettings(context),
                ),
                _buildMenuItem(
                  icon: 'settingglobal',
                  title: '语言',
                  subtitle: '简体中文',
                  onTap: () => _openLanguageSettings(context),
                ),
                _buildMenuItem(
                  icon: 'settinginfo',
                  title: '关于我们',
                  subtitle: '版本 1.0.0',
                  onTap: () => _openAboutPage(context),
                ),
                
              ],
            ),
          ),
          
      
          
          // 退出登录按钮
          _buildLogoutButton(context, globalController),
          
          const SizedBox(height: 46),
        ],
      ),
    );
  }

  /// 构建用户信息头部
  Widget _buildUserHeader(GlobalController controller) {
    return Obx(() {
      final user = controller.currentUser.value;
      final avatar = user?.avatar;
      final nickname = user?.nickname ?? '未设置昵称';
      final userId = user?.id ?? '';



      return Container(
        padding:  EdgeInsets.only(top: 16, left: 20, right: 20),
        decoration: BoxDecoration(
          color:  const Color.fromARGB(255, 146, 192, 245),
          image: DecorationImage(
            image: AssetImage('assets/img/user/settingheaderbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child:  SafeArea(
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
            GestureDetector(
              onTap: () => Get.toNamed('/profile'),
              child: _userHeadImgView(avatar ?? '', nickname, userId),
            ),
            
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: () {
                Get.to(() => const ProfilePage());
              },
              child: Row(
                children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 昵称
            Text(
              nickname,
              style: const TextStyle(
                color: GbsColors.lightTitlePrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // ID
            if (userId.isNotEmpty)
              Text(
                'ID: $userId',
                style: TextStyle(
                  color: GbsColors.lightTitlePrimary,
                  fontSize: 13,
                ),
              ),
                ],),
                Spacer(),
                Image.asset(  'assets/img/user/arrow.png', width: 16, height: 16)
              ],),
            )
          ],
        ),
      ));
    });
  }

  Future<String> _fetchUserAvatarUrl(String userId) async {
    await Future.delayed(Duration(seconds: 2));
    // 从数据库获取用户信息
    Map<String, dynamic>? res = await _messageDatabase.getUser(userId);
    String bg = res?['avatar_bg'] ?? '';

    
    return bg;
  }

  Widget _userHeadImgView(String avatar, String nickname, String userId){
    return FutureBuilder(future: _fetchUserAvatarUrl(userId), builder: (context, AsyncSnapshot<String> snapshot) {


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


      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          image: avatar.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(avatar),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: CircleAvatar(
            radius: 18,
            
            backgroundColor: bgColor,
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
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
          ),
      );
    });
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        child: Image.asset( 'assets/img/user/$icon.png', width: 24, height: 24, fit: BoxFit.fill,)
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton(BuildContext context, GlobalController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutConfirm(context, controller),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            '退出登录',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  /// 打开通知设置
  void _openNotificationSettings(BuildContext context) async {
    Navigator.pop(context);
    await Get.to(() => const NotificationPage());
    _loadNotificationUnread();
  }

  /// 打开安全设置
  void _openSecuritySettings(BuildContext context) {
    Navigator.pop(context);
    Get.to(() => const SecuritySettingsPage());
  }

  /// 打开语言设置
  void _openLanguageSettings(BuildContext context) {
    Navigator.pop(context);
    _showLanguageDialog(context);
  }

  /// 打开关于我们
  void _openAboutPage(BuildContext context) {
    Navigator.pop(context);
    _showAboutDialog(context);
  }

  /// 显示语言选择对话框
  void _showLanguageDialog(BuildContext context) {
    Get.to(() => const LanguagePage());
  }

  /// 显示关于我们对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('铃鸟聊天'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('版本: 1.0.0'),
            const SizedBox(height: 8),
            Text(
              '一款简洁高效的即时通讯应用',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 铃鸟科技',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示退出登录确认
  void _showLogoutConfirm(BuildContext context, GlobalController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 关闭侧边栏
              controller.logout();
              EasyLoading.showSuccess('已退出登录');
              await Future.delayed(const Duration(seconds: 1));
              Get.offAllNamed('/login');
            },
            child: const Text(
              '退出',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示侧边栏菜单
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

