import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../services/native_bridge.dart';
import '../../controllers/global_controller.dart';

/// 修改密码页面
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final IOSNativeService _nativeService = IOSNativeService();
  final GlobalController _globalController = Get.find<GlobalController>();
  
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 修改密码
  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    // 验证输入
    if (oldPassword.isEmpty) {
      EasyLoading.showError('请输入当前密码');
      return;
    }
    
    if (newPassword.isEmpty) {
      EasyLoading.showError('请输入新密码');
      return;
    }
    
    if (newPassword.length < 6) {
      EasyLoading.showError('密码长度不能少于6位');
      return;
    }
    
    if (newPassword == oldPassword) {
      EasyLoading.showError('新密码不能与当前密码相同');
      return;
    }
    
    if (confirmPassword != newPassword) {
      EasyLoading.showError('两次密码输入不一致');
      return;
    }

    setState(() => _isLoading = true);
    EasyLoading.show(status: '正在修改密码...');

    try {
      final currentUser = _globalController.currentUser.value;
      if (currentUser == null || currentUser.id.isEmpty) {
        EasyLoading.showError('用户未登录');
        return;
      }

      final result = await _nativeService.imChangePassword(
        userId: currentUser.id,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      
      print('🔐 修改密码结果: $result');
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('密码修改成功');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
      } else {
        EasyLoading.showError(result['message'] ?? '修改失败');
      }
    } catch (e) {
      print('修改密码错误: $e');
      EasyLoading.showError('修改失败，请稍后重试');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '为了您的账户安全，请定期修改密码',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 当前密码
            _buildPasswordField(
              controller: _oldPasswordController,
              label: '当前密码',
              hint: '请输入当前密码',
              obscureText: _obscureOldPassword,
              onToggleVisibility: () {
                setState(() => _obscureOldPassword = !_obscureOldPassword);
              },
            ),
            
            const SizedBox(height: 20),
            
            // 新密码
            _buildPasswordField(
              controller: _newPasswordController,
              label: '新密码',
              hint: '请输入新密码（至少6位）',
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
            ),
            
            const SizedBox(height: 20),
            
            // 确认新密码
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: '确认新密码',
              hint: '请再次输入新密码',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            
            const SizedBox(height: 40),
            
            // 提交按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '确认修改',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建密码输入框
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}

