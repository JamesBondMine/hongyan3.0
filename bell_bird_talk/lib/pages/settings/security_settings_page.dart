import 'dart:convert';

import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'change_password_page.dart';
import 'reset_password_page.dart';

/// 安全设置页面
class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  Map<String, dynamic>? _deactivateStatus;
  

  @override
  void initState() {
    super.initState();
    _loadDeactivateStatus();
  }

  /// 加载注销状态
  Future<void> _loadDeactivateStatus() async {
    try {
      final globalController = Get.find<GlobalController>();
      final userId = globalController.currentUser.value?.id;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final result = await _nativeService.imGetDeactivateStatus(userId: userId);
      if (!mounted) return;

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr) as Map<String, dynamic>;
            setState(() {
              _deactivateStatus = data;
            });
          } catch (e) {
            print('解析注销状态失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取注销状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    
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

          _buildDeactivateMenuItem(
                  icon: 'settingnoti',
                  title: _getDeactivateStatusTitle(),
                  subtitle: _getDeactivateStatusSubtitle(),
                  onTap: () => _showDeleteAccountConfirm(context, globalController),
                ),
        ],
      ),
    );
  }


  /// 获取注销状态标题
  String _getDeactivateStatusTitle() {
    if (_deactivateStatus == null) {
      return '注销账号';
    }
    
    final status = _deactivateStatus!['status'] as int?;
    
    // 状态枚举值：Normal=0, Cooling=1, PendingReview=2, Deactivated=3
    switch (status) {
      case 0: // Normal
        return '注销账号';
      case 1: // Cooling
        return '注销账号（冷却期）';
      case 2: // PendingReview
        return '注销账号（审核中）';
      case 3: // Deactivated
        return '账号已注销';
      default:
        return '注销账号';
    }
  }
  
  /// 获取注销状态副标题
  String _getDeactivateStatusSubtitle() {
    if (_deactivateStatus == null) {
      return '注销后账号将无法恢复';
    }
    
    final status = _deactivateStatus!['status'] as int?;
    final requestTime = _deactivateStatus!['request_time'] as int?;
    final reviewTime = _deactivateStatus!['review_time'] as int?;
    
    // 状态枚举值：Normal=0, Cooling=1, PendingReview=2, Deactivated=3
    switch (status) {
      case 0: // Normal
        return '注销后账号将无法恢复';
      case 1: // Cooling
        if (requestTime != null && requestTime > 0) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(requestTime);
          return '冷却期，申请时间：${_formatDateTime(dateTime)}';
        }
        return '账号处于冷却期';
      case 2: // PendingReview
        if (requestTime != null && requestTime > 0) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(requestTime);
          return '审核中，申请时间：${_formatDateTime(dateTime)}';
        }
        return '注销申请审核中';
      case 3: // Deactivated
        if (reviewTime != null && reviewTime > 0) {
          final dateTime = DateTime.fromMillisecondsSinceEpoch(reviewTime);
          return '已注销，注销时间：${_formatDateTime(dateTime)}';
        }
        return '账号已注销';
      default:
        return '注销后账号将无法恢复';
    }
  }



  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 显示注销账号确认
  void _showDeleteAccountConfirm(BuildContext context, GlobalController controller) {
    // 检查当前注销状态
    final status = _deactivateStatus?['status'] as int?;
    
    // 如果已经注销或正在审核中，显示状态信息
    if (status == 3) { // Deactivated - 已注销
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('账号已注销'),
          content: Text(_getDeactivateStatusSubtitle()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }
    
    if (status == 2) { // PendingReview - 审核中
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('注销申请审核中'),
          content: Text(_getDeactivateStatusSubtitle()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }
    
    if (status == 1) { // Cooling - 冷却期
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('账号处于冷却期'),
          content: Text(_getDeactivateStatusSubtitle()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // 关闭对话框
                await _cancelDeactivateAccount(context, controller);
              },
              child: const Text(
                '撤回注销',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
      return;
    }
    
    // Normal 状态，显示注销确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text('注销账号后，您的所有数据（包括好友、聊天记录等）将被永久删除且无法恢复，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 关闭对话框
              await _deactivateAccount(context, controller);
            },
            child: const Text(
              '确定注销',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 执行注销账号
  Future<void> _deactivateAccount(BuildContext context, GlobalController controller) async {
    EasyLoading.show(status: '正在注销账号...');
    
    try {
      final userId = controller.currentUser.value?.id;
      if (userId == null || userId.isEmpty) {
        EasyLoading.dismiss();
        EasyLoading.showError('无法获取用户ID');
        return;
      }
      
      final nativeService = IOSNativeService();
      final result = await nativeService.imDeactivateAccount(
        userId: userId,
        reason: '用户主动注销',
      );
      
      EasyLoading.dismiss();
      
      final errorCode = result['errorCode'] as int? ?? -1;
      final message = result['message'] as String? ?? '未知错误';
      
      if (errorCode == 0) {
        // 注销成功，刷新注销状态
        await _loadDeactivateStatus();
        EasyLoading.showSuccess('账号注销申请成功');
        
      } else {
        // 注销失败
        EasyLoading.showError(message);
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('注销失败: $e');
    }
  }

  /// 执行撤回注销账号
  Future<void> _cancelDeactivateAccount(BuildContext context, GlobalController controller) async {
    EasyLoading.show(status: '正在撤回注销...');
    
    try {
      final userId = controller.currentUser.value?.id;
      if (userId == null || userId.isEmpty) {
        EasyLoading.dismiss();
        EasyLoading.showError('无法获取用户ID');
        return;
      }
      
      final nativeService = IOSNativeService();
      final result = await nativeService.imCancelDeactivateAccount(userId: userId);
      
      EasyLoading.dismiss();
      
      final errorCode = result['errorCode'] as int? ?? -1;
      final message = result['message'] as String? ?? '未知错误';
      
      if (errorCode == 0) {
        // 撤回成功，刷新注销状态
        await _loadDeactivateStatus();
        EasyLoading.showSuccess('撤回注销成功');
        
      } else {
        // 撤回失败
        EasyLoading.showError(message);
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('撤回注销失败: $e');
    }
  }
// 构建菜单项
// 构建菜单项
  Widget _buildDeactivateMenuItem({
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

