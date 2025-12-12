import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'change_password_page.dart';
import 'reset_password_page.dart';

/// 安全设置页面
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 修改密码
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '修改密码',
            subtitle: '更改当前登录密码',
            onTap: () {
              Get.to(() => const ChangePasswordPage());
            },
          ),
          
          const Divider(height: 1),
          
          // 重置密码
          _buildMenuItem(
            icon: Icons.lock_reset,
            title: '重置密码',
            subtitle: '忘记密码时重置',
            onTap: () {
              Get.to(() => const ResetPasswordPage());
            },
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
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
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}

