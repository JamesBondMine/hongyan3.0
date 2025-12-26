import 'dart:convert';
import 'package:bell_bird_talk/pages/profile/profile_page.dart';
import 'package:bell_bird_talk/pages/settings/language_page.dart';
import 'package:bell_bird_talk/pages/settings/security_settings_page.dart';
import 'package:bell_bird_talk/pages/notification/notification_page.dart';
import 'package:bell_bird_talk/utils/app_colors.dart';
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
  Map<String, dynamic>? _deactivateStatus;  // 注销状态信息

  @override
  void initState() {
    super.initState();
    _loadNotificationUnread();
    _loadDeactivateStatus();
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
                _buildMenuItem(
                  icon: 'settingnoti',
                  title: _getDeactivateStatusTitle(),
                  subtitle: _getDeactivateStatusSubtitle(),
                  onTap: () => _showDeleteAccountConfirm(context, globalController),
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
                color: AppColors.lightTitlePrimary,
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
                  color: AppColors.lightTitlePrimary,
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
        // decoration: BoxDecoration(
        //   color: Colors.blue.withOpacity(0.1),
        //   borderRadius: BorderRadius.circular(10),
        // ),
        child: Image.asset( 'assets/img/user/$icon.png', width: 24, height: 24, fit: BoxFit.fill,)
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      // subtitle: subtitle != null
      //     ? Text(
      //         subtitle,
      //         style: TextStyle(
      //           fontSize: 13,
      //           color: Colors.grey[500],
      //         ),
      //       )
      //     : null,
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

