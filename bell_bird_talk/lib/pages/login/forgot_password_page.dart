import 'dart:async';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

/// 重置方式枚举
enum ResetType {
  phone,  // 手机号重置
  email,  // 邮箱重置
}

/// 忘记密码页面
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // 文本控制器
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // 原生服务
  final IOSNativeService _nativeService = IOSNativeService();
  
  // 状态
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
    String codeType;
    
    if (_resetType == ResetType.phone) {
      target = _phoneController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入手机号');
        return;
      }
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(target)) {
        EasyLoading.showError('请输入正确的手机号');
        return;
      }
      codeType = 'sms';
    } else {
      target = _emailController.text.trim();
      if (target.isEmpty) {
        EasyLoading.showError('请输入邮箱');
        return;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(target)) {
        EasyLoading.showError('请输入正确的邮箱');
        return;
      }
      codeType = 'email';
    }

    setState(() => _isSendingCode = true);
    
    try {
      final result = await _nativeService.imGetCaptcha(
        target,
        type: codeType.toUpperCase(),  // SMS 或 EMAIL
        scene: 'reset_password',
      );
      
      print('📮 发送验证码结果: $result');
      
      if (result['errorCode'] == 0) {
        // 解析验证码ID
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final parsed = RegExp(r'"captcha_id"\s*:\s*"([^"]+)"').firstMatch(data);
            if (parsed != null) {
              _captchaId = parsed.group(1);
            }
          } catch (e) {
            print('解析captchaId失败: $e');
          }
        }
        
        // 直接从 result 中获取 captcha_id
        _captchaId ??= result['captcha_id'] as String?;
        
        print('📮 获取到验证码ID: $_captchaId');
        
        EasyLoading.showSuccess('验证码已发送');
        _startCountdown();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildAppBar(),
              
              // 内容区域
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建导航栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              '忘记密码',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // 占位，保持标题居中
        ],
      ),
    );
  }

  /// 构建表单
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Center(
            child: Text(
              '重置密码',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              '请选择验证方式重置您的密码',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 重置方式切换
          _buildResetTypeTabs(),
          
          const SizedBox(height: 24),
          
          // 手机号/邮箱输入
          if (_resetType == ResetType.phone)
            _buildPhoneInput()
          else
            _buildEmailInput(),
          
          const SizedBox(height: 16),
          
          // 验证码输入
          _buildCodeInputRow(),
          
          const SizedBox(height: 16),
          
          // 新密码输入
          _buildPasswordInput(),
          
          const SizedBox(height: 16),
          
          // 确认密码输入
          _buildConfirmPasswordInput(),
          
          const SizedBox(height: 24),
          
          // 重置按钮
          _buildResetButton(),
          
          const SizedBox(height: 16),
          
          // 返回登录
          _buildBackToLoginButton(),
        ],
      ),
    );
  }

  /// 重置方式切换 Tab
  Widget _buildResetTypeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(
            title: '手机号重置',
            isSelected: _resetType == ResetType.phone,
            onTap: () => _switchResetType(ResetType.phone),
          ),
          _buildTabItem(
            title: '邮箱重置',
            isSelected: _resetType == ResetType.email,
            onTap: () => _switchResetType(ResetType.email),
          ),
        ],
      ),
    );
  }

  /// Tab 项
  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// 手机号输入
  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: '手机号',
        hintText: '请输入绑定的手机号',
        prefixIcon: const Icon(Icons.phone_android),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// 邮箱输入
  Widget _buildEmailInput() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: '邮箱',
        hintText: '请输入绑定的邮箱',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// 验证码输入行
  Widget _buildCodeInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '验证码',
              hintText: '请输入验证码',
              prefixIcon: const Icon(Icons.security),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          height: 56,
          child: ElevatedButton(
            onPressed: _countdown > 0 || _isSendingCode
                ? null
                : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isSendingCode
                ? const SizedBox(
                    width: 20,
                    height: 20,
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
      ],
    );
  }

  /// 新密码输入
  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '新密码',
        hintText: '请输入新密码（至少6位）',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// 确认密码输入
  Widget _buildConfirmPasswordInput() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: '确认密码',
        hintText: '请再次输入新密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// 重置按钮
  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '重置密码',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 返回登录按钮
  Widget _buildBackToLoginButton() {
    return Center(
      child: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          '返回登录',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

