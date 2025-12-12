import 'package:bell_bird_talk/pages/settings/language_page.dart';
import 'package:bell_bird_talk/pages/settings/security_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../controllers/global_controller.dart';

/// 侧边栏菜单内容
class SideMenuContent extends StatelessWidget {
  const SideMenuContent({super.key});

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    
    return SafeArea(
      child: Column(
        children: [
          // 用户信息头部
          _buildUserHeader(globalController),
          
          const Divider(height: 1),
          
          // 菜单列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: '通知',
                  subtitle: '消息提醒设置',
                  onTap: () => _openNotificationSettings(context),
                ),
                _buildMenuItem(
                  icon: Icons.security_outlined,
                  title: '安全设置',
                  subtitle: '密码、隐私管理',
                  onTap: () => _openSecuritySettings(context),
                ),
                _buildMenuItem(
                  icon: Icons.language_outlined,
                  title: '语言',
                  subtitle: '简体中文',
                  onTap: () => _openLanguageSettings(context),
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: '关于我们',
                  subtitle: '版本 1.0.0',
                  onTap: () => _openAboutPage(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 退出登录按钮
          _buildLogoutButton(context, globalController),
          
          const SizedBox(height: 16),
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
      final email = user?.email ?? '';
      final phone = user?.phone ?? '';
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: Column(
          children: [
            // 头像
            GestureDetector(
              onTap: () => Get.toNamed('/profile'),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Text(
                        nickname.isNotEmpty ? nickname.substring(0, 1) : '我',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 昵称
            Text(
              nickname,
              style: const TextStyle(
                color: Colors.white,
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
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // 邮箱/手机
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (email.isNotEmpty) ...[
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _maskEmail(email),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ] else if (phone.isNotEmpty) ...[
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _maskPhone(phone),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 查看资料按钮
            OutlinedButton(
              onPressed: () => Get.toNamed('/profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '查看个人资料',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.blue,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            )
          : null,
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
  void _openNotificationSettings(BuildContext context) {
    Navigator.pop(context);
    EasyLoading.showInfo('通知设置（开发中）');
    // TODO: Get.toNamed('/settings/notification');
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
              await controller.logout();
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

  /// 隐藏邮箱中间部分
  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}***@$domain';
  }

  /// 隐藏手机号中间部分
  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}

/// 显示侧边栏菜单
void showSideMenu(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final menuWidth = screenWidth * 0.75; // 3/4 屏幕宽度
  
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

