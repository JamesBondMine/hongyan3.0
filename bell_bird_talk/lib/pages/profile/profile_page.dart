import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../controllers/global_controller.dart';

/// 个人资料页面
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalController _globalCtrl = Get.find<GlobalController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('个人资料'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => EasyLoading.showInfo('我的二维码'),
          ),
        ],
      ),
      body: Obx(() {
        final user = _globalCtrl.currentUser.value;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // 头部信息卡片
              _buildHeaderCard(user),
              
              const SizedBox(height: 12),
              
              // 基本信息
              _buildBasicInfoSection(user),
              
              const SizedBox(height: 12),
              
              // 账号安全
              _buildAccountSecuritySection(user),
              
              const SizedBox(height: 12),
              
              // 更多设置
              _buildSettingsSection(),
              
              const SizedBox(height: 24),
              
              // 退出登录按钮
              _buildLogoutButton(),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }
  
  /// 头部信息卡片
  Widget _buildHeaderCard(user) {
    return Container(
      color: Colors.blue,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // 头像（可点击更换）
            GestureDetector(
              onTap: () => _showAvatarOptions(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? NetworkImage(user!.avatar!)
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.blue)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 昵称（可点击编辑）
            GestureDetector(
              onTap: () => _showEditNicknameDialog(user?.nickname),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.nickname ?? '未设置昵称',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 账号ID
            GestureDetector(
              onTap: () => _copyToClipboard(user?.username ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '账号: ${user?.username ?? '未知'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  /// 基本信息区域
  Widget _buildBasicInfoSection(user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('基本信息'),
          
          _buildInfoItem(
            icon: Icons.fingerprint,
            label: '用户ID',
            value: user?.id ?? '未知',
            canCopy: true,
          ),
          
          _buildInfoItem(
            icon: Icons.badge,
            label: '账号ID',
            value: user?.username ?? '未设置',
            canCopy: true,
          ),
          
          _buildInfoItem(
            icon: Icons.wc,
            label: '性别',
            value: _getGenderText(user?.gender),
            onTap: () => _showGenderPicker(user?.gender),
          ),
          
          _buildInfoItem(
            icon: Icons.edit_note,
            label: '个性签名',
            value: user?.signature ?? '未设置',
            onTap: () => _showEditSignatureDialog(user?.signature),
          ),
          
          _buildInfoItem(
            icon: Icons.cake,
            label: '注册时间',
            value: user?.createdAt?.toString().substring(0, 10) ?? '未知',
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 账号安全区域
  Widget _buildAccountSecuritySection(user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('账号安全'),
          
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '手机号',
            value: _maskPhone(user?.phone),
            trailing: user?.phone != null && user!.phone!.isNotEmpty
                ? _buildBindBadge('已绑定', Colors.green)
                : _buildBindBadge('未绑定', Colors.orange),
            onTap: () => _showPhoneBindDialog(user?.phone),
          ),
          
          _buildInfoItem(
            icon: Icons.email,
            label: '邮箱',
            value: _maskEmail(user?.email),
            trailing: user?.email != null && user!.email!.isNotEmpty
                ? _buildBindBadge('已绑定', Colors.green)
                : _buildBindBadge('未绑定', Colors.orange),
            onTap: () => _showEmailBindDialog(user?.email),
          ),
          
          _buildInfoItem(
            icon: Icons.lock,
            label: '修改密码',
            value: '',
            onTap: () => EasyLoading.showInfo('修改密码功能开发中'),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 更多设置区域
  Widget _buildSettingsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('更多设置'),
          
          _buildInfoItem(
            icon: Icons.notifications,
            label: '消息通知',
            value: '',
            onTap: () => EasyLoading.showInfo('消息通知设置'),
          ),
          
          _buildInfoItem(
            icon: Icons.privacy_tip,
            label: '隐私设置',
            value: '',
            onTap: () => EasyLoading.showInfo('隐私设置'),
          ),
          
          _buildInfoItem(
            icon: Icons.storage,
            label: '存储空间',
            value: '',
            onTap: () => EasyLoading.showInfo('存储空间管理'),
          ),
          
          _buildInfoItem(
            icon: Icons.info_outline,
            label: '关于我们',
            value: '',
            onTap: () => EasyLoading.showInfo('铃鸟聊天 v1.0.0'),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 区块标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  /// 信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? (canCopy && value.isNotEmpty && !value.contains('未') 
          ? () => _copyToClipboard(value) 
          : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
            if (canCopy && value.isNotEmpty && !value.contains('未')) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, color: Colors.grey[400], size: 16),
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 绑定状态徽章
  Widget _buildBindBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  /// 退出登录按钮
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _confirmLogout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: const Text(
            '退出登录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  // ==================== 工具方法 ====================
  
  String _getGenderText(int? gender) {
    switch (gender) {
      case 1: return '男';
      case 2: return '女';
      default: return '未设置';
    }
  }
  
  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '未绑定';
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }
  
  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '未绑定';
    final index = email.indexOf('@');
    if (index > 2) {
      return '${email.substring(0, 2)}***${email.substring(index)}';
    }
    return email;
  }
  
  void _copyToClipboard(String text) {
    if (text.isEmpty || text.contains('未')) return;
    Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制');
  }
  
  // ==================== 弹窗和操作 ====================
  
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('拍照'),
              onTap: () {
                Get.back();
                EasyLoading.showInfo('相机功能开发中');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('从相册选择'),
              onTap: () {
                Get.back();
                EasyLoading.showInfo('相册功能开发中');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('取消', textAlign: TextAlign.center),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditNicknameDialog(String? currentNickname) {
    final controller = TextEditingController(text: currentNickname);
    
    Get.dialog(
      AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '请输入新昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: 调用修改昵称接口
              EasyLoading.showSuccess('昵称修改成功');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showEditSignatureDialog(String? currentSignature) {
    final controller = TextEditingController(text: currentSignature);
    
    Get.dialog(
      AlertDialog(
        title: const Text('修改签名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '请输入个性签名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: 调用修改签名接口
              EasyLoading.showSuccess('签名修改成功');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showGenderPicker(int? currentGender) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择性别',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.male, color: Colors.blue),
              title: const Text('男'),
              trailing: currentGender == 1 
                  ? const Icon(Icons.check, color: Colors.blue) 
                  : null,
              onTap: () {
                Get.back();
                // TODO: 调用修改性别接口
                EasyLoading.showSuccess('性别已修改');
              },
            ),
            ListTile(
              leading: const Icon(Icons.female, color: Colors.pink),
              title: const Text('女'),
              trailing: currentGender == 2 
                  ? const Icon(Icons.check, color: Colors.blue) 
                  : null,
              onTap: () {
                Get.back();
                // TODO: 调用修改性别接口
                EasyLoading.showSuccess('性别已修改');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showPhoneBindDialog(String? currentPhone) {
    if (currentPhone != null && currentPhone.isNotEmpty) {
      // 已绑定，显示换绑选项
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: const Text('更换手机号'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑手机号功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text('解绑手机号'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑手机号功能开发中');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定手机号功能开发中');
    }
  }
  
  void _showEmailBindDialog(String? currentEmail) {
    if (currentEmail != null && currentEmail.isNotEmpty) {
      // 已绑定，显示换绑选项
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: const Text('更换邮箱'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑邮箱功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text('解绑邮箱'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑邮箱功能开发中');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定邮箱功能开发中');
    }
  }
  
  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              EasyLoading.show(status: '退出中...');
              await _globalCtrl.logout();
              EasyLoading.dismiss();
              Get.offAllNamed('/login');
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

