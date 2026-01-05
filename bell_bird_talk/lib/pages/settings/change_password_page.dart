import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../services/native_bridge.dart';
import '../../controllers/global_controller.dart';

/// 修改密码页面
class ChangePasswordPage extends StatefulWidget {

  String oldPwd = '';
  ChangePasswordPage({super.key, required this.oldPwd});

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
    final oldPassword = widget.oldPwd;
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNewPwdInput(_newPasswordController),
            const SizedBox(height: 20),

            _buildConfirmPwdInput(_confirmPasswordController),
   
            Padding(padding: EdgeInsetsGeometry.only(top: 8),child: Text('密码长度6-16位，需包含数字、字母、特殊符号中的两种', style: TextStyle(fontSize: 12,color: GbsColors.des9Color),),),
            const SizedBox(height: 20),

            CommonButton(text:  '完成',
              enabled: _newPasswordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty,
              onPressed: () {
                if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
                  // EasyLoading.showError('请输入邀请码');
                  return;
                }
                _changePassword();
              },
            ),
      
          ],
        ),
      ),
    );
  }


  /// 邀请码输入框
  Widget _buildNewPwdInput(TextEditingController controller) {
    return LoginTextField(
      controller: controller,
      title: '新密码',
      hintText: '请输入原密码',
      obscureText: true,
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
    );
  }

  /// 邀请码输入框
  Widget _buildConfirmPwdInput(TextEditingController controller) {
    return LoginTextField(
      controller: controller,
      title: '二次确认',
      hintText: '请输入原密码',
      obscureText: true,
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
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

