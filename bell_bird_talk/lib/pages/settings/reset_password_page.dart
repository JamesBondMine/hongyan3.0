import 'dart:async';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../services/native_bridge.dart';

/// 重置方式枚举
enum ResetType {
  phone,  // 手机号重置
  email,  // 邮箱重置
}

/// 重置密码页面
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final IOSNativeService _nativeService = IOSNativeService();
  
  ResetType _resetType = ResetType.phone;
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;
  Timer? _countdownTimer;
  String? _captchaId;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 切换重置方式
  void _switchResetType(ResetType type) {
    setState(() {
      _resetType = type;
      _codeController.clear();
      _captchaId = null;
      _countdown = 0;
      _countdownTimer?.cancel();
    });
  }

  /// 发送验证码
  Future<void> _sendVerificationCode() async {
    String target;
    String type;
    if (_resetType == ResetType.phone) {
      target = _phoneController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入手机号');
        return;
      }
      type = 'SMS';
    } else {
      target = _emailController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入邮箱');
        return;
      }
      type = 'EMAIL';
    }

    setState(() => _isSendingCode = true);
    EasyLoading.show(status: '正在发送验证码...');

    try {
      final result = await _nativeService.imGetCaptcha(
        target,
        type: type,
        scene: 'resetPassword',
      );
      
      print('📧 验证码结果: $result');
      
      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null) {
          final dataMap = data is String ? 
              (data.isNotEmpty ? {'captcha_id': data} : null) : 
              (data is Map ? data : null);
          
          if (dataMap != null && dataMap['captcha_id'] != null) {
            _captchaId = dataMap['captcha_id'].toString();
            _startCountdown();
            EasyLoading.showSuccess('验证码已发送');
          } else {
            EasyLoading.showError('获取验证码失败');
          }
        } else {
          EasyLoading.showError('获取验证码失败');
        }
      } else {
        EasyLoading.showError(result['message'] ?? '发送失败');
      }
    } catch (e) {
      print('发送验证码错误: $e');
      EasyLoading.showError('发送失败，请稍后重试');
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  /// 重置密码
  Future<void> _resetPassword() async {
    // 验证输入
    String target;
    if (_resetType == ResetType.phone) {
      target = _phoneController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入手机号');
        return;
      }
    } else {
      target = _emailController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入邮箱');
        return;
      }
    }
    
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      EasyLoading.showError('请输入验证码');
      return;
    }
    
    final password = _passwordController.text;
    if (password.isEmpty) {
      EasyLoading.showError('请输入新密码');
      return;
    }
    
    if (password.length < 6) {
      EasyLoading.showError('密码长度不能少于6位');
      return;
    }
    
    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword != password) {
      EasyLoading.showError('两次密码输入不一致');
      return;
    }
    
    if (_captchaId == null) {
      EasyLoading.showError('请先获取验证码');
      return;
    }

    setState(() => _isLoading = true);
    EasyLoading.show(status: '正在重置密码...');

    try {
      final result = await _nativeService.imResetPassword(
        phone: _resetType == ResetType.phone ? target : null,
        email: _resetType == ResetType.email ? target : null,
        code: code,
        captchaId: _captchaId!,
        newPassword: password,
      );
      
      print('🔐 重置密码结果: $result');
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('密码重置成功');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAll(LoginPage());
      } else {
        EasyLoading.showError(result['message'] ?? '重置失败');
      }
    } catch (e) {
      print('重置密码错误: $e');
      EasyLoading.showError('重置失败，请稍后重试');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('重置密码'),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '忘记密码时，可通过手机号或邮箱重置',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 重置方式选择
            Row(
              children: [
                Expanded(
                  child: _buildResetTypeButton(
                    type: ResetType.phone,
                    icon: Icons.phone,
                    label: '手机号',
                    isSelected: _resetType == ResetType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResetTypeButton(
                    type: ResetType.email,
                    icon: Icons.email,
                    label: '邮箱',
                    isSelected: _resetType == ResetType.email,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 手机号/邮箱输入
            if (_resetType == ResetType.phone)
              _buildTextField(
                controller: _phoneController,
                label: '手机号',
                hint: '请输入手机号',
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
              )
            else
              _buildTextField(
                controller: _emailController,
                label: '邮箱',
                hint: '请输入邮箱',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
            
            const SizedBox(height: 20),
            
            // 验证码输入
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _codeController,
                    label: '验证码',
                    hint: '请输入验证码',
                    keyboardType: TextInputType.number,
                    icon: Icons.verified_user_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: ElevatedButton(
                      onPressed: (_isSendingCode || _countdown > 0) ? null : _sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _countdown > 0 ? '${_countdown}s' : '获取验证码',
                              style: const TextStyle(fontSize: 13),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 新密码
            _buildPasswordField(
              controller: _passwordController,
              label: '新密码',
              hint: '请输入新密码（至少6位）',
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
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
              onPressed: _isLoading ? null : _resetPassword,
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
                      '确认重置',
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

  /// 构建重置方式按钮
  Widget _buildResetTypeButton({
    required ResetType type,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _switchResetType(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required IconData icon,
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
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
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

