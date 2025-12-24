import 'dart:convert';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// 注册方式枚举
enum RegisterType {
  accountPassword, // 账号密码注册
  phoneCode,       // 手机验证码注册
  emailCode,       // 邮箱验证码注册
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _verifyCodeController = TextEditingController();
  final _emailVerifyCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _nativeService = IOSNativeService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  int _countdown = 0;
  int _emailCountdown = 0;
  String? _captchaId; // 存储手机验证码 ID
  String? _emailCaptchaId; // 存储邮箱验证码 ID
  RegisterType _registerType = RegisterType.phoneCode; // 默认手机验证码注册

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _verifyCodeController.dispose();
    _emailVerifyCodeController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
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
              
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Logo 和标题
                      _buildHeader(),
                      
                      const SizedBox(height: 30),
                      
                      // 注册方式切换
                      _buildRegisterTypeSwitch(),
                      
                      const SizedBox(height: 20),
                      
                      // 注册表单
                      _buildRegisterForm(),
                      
                      const SizedBox(height: 30),
                      
                      // 用户协议
                      _buildTermsCheckbox(),
                      
                      const SizedBox(height: 20),
                      
                      // 注册按钮
                      _buildRegisterButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const Text(
            '返回登录',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Logo 和标题
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
 
        
        // 标题
        const Text(
          '创建新账号',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 副标题
        Text(
          '欢迎加入我们',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  /// 注册方式切换
  Widget _buildRegisterTypeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              title: '手机注册',
              isSelected: _registerType == RegisterType.phoneCode,
              onTap: () {
                setState(() {
                  _registerType = RegisterType.phoneCode;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              title: '邮箱注册',
              isSelected: _registerType == RegisterType.emailCode,
              onTap: () {
                setState(() {
                  _registerType = RegisterType.emailCode;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              title: '账号注册',
              isSelected: _registerType == RegisterType.accountPassword,
              onTap: () {
                setState(() {
                  _registerType = RegisterType.accountPassword;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 注册类型按钮
  Widget _buildTypeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue.shade700 : Colors.white,
          ),
        ),
      ),
    );
  }

  /// 注册表单
  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // 根据注册类型显示不同字段
            if (_registerType == RegisterType.accountPassword) ...[
              // 账号注册：账号
              _buildTextField(
                controller: _accountController,
                label: '账号',
                hint: '请输入账号（4-16位字母数字）',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入账号';
                  }
                  if (value.length < 4 || value.length > 16) {
                    return '账号长度为4-16位';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                    return '账号只能包含字母和数字';
                  }
                  return null;
                },
              ),
            ] else if (_registerType == RegisterType.phoneCode) ...[
              // 手机注册：手机号
              _buildTextField(
                controller: _phoneController,
                label: '手机号',
                hint: '请输入手机号',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入手机号';
                  }
                  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                    return '请输入正确的手机号';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 手机验证码输入框
              _buildVerifyCodeField(),
            ] else if (_registerType == RegisterType.emailCode) ...[
              // 邮箱注册：邮箱
              _buildTextField(
                controller: _emailController,
                label: '邮箱',
                hint: '请输入邮箱地址',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱';
                  }
                  if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(value)) {
                    return '请输入正确的邮箱地址';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 邮箱验证码输入框
              _buildEmailVerifyCodeField(),
            ],
            
            const SizedBox(height: 20),
            
            // 密码输入框（两种方式都需要）
            _buildTextField(
              controller: _passwordController,
              label: '密码',
              hint: '请输入密码（6-20位）',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6 || value.length > 20) {
                  return '密码长度为6-20位';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // 确认密码输入框（两种方式都需要）
            _buildTextField(
              controller: _confirmPasswordController,
              label: '确认密码',
              hint: '请再次输入密码',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请再次输入密码';
                }
                if (value != _passwordController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // 邀请码（可选）
            _buildTextField(
              controller: _inviteCodeController,
              label: '邀请码（可选）',
              hint: '请输入邀请码',
              prefixIcon: Icons.card_giftcard_outlined,
              validator: null, // 可选字段，不验证
            ),
          ],
        ),
      ),
    );
  }

  /// 验证码输入框（带获取按钮）
  Widget _buildVerifyCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '验证码',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _verifyCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '请输入验证码',
                  prefixIcon: const Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入验证码';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              height: 56,
              child: ElevatedButton(
                onPressed: _countdown > 0 ? null : _getVerifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _countdown > 0 ? '${_countdown}s' : '获取验证码',
                  style: TextStyle(
                    fontSize: 14,
                    color: _countdown > 0 ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 邮箱验证码输入框（带获取按钮）
  Widget _buildEmailVerifyCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '验证码',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailVerifyCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '请输入邮箱验证码',
                  prefixIcon: const Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入验证码';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              height: 56,
              child: ElevatedButton(
                onPressed: _emailCountdown > 0 ? null : _getEmailVerifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _emailCountdown > 0 ? '${_emailCountdown}s' : '获取验证码',
                  style: TextStyle(
                    fontSize: 14,
                    color: _emailCountdown > 0 ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 通用文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// 用户协议勾选
  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeTerms,
          onChanged: (value) {
            setState(() {
              _agreeTerms = value ?? false;
            });
          },
          activeColor: Colors.white,
          checkColor: Colors.blue,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeTerms = !_agreeTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                children: [
                  const TextSpan(text: '我已阅读并同意'),
                  TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 注册按钮
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: const Text(
          '立即注册',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 获取验证码
  void _getVerifyCode() async {
    // 验证手机号
    if (_phoneController.text.isEmpty) {
      EasyLoading.showError('请先输入手机号');
      return;
    }
    
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneController.text)) {
      EasyLoading.showError('请输入正确的手机号');
      return;
    }
    
    try {
      EasyLoading.show(status: '发送中...');
      
      // 调用 Native 获取短信验证码接口
      final result = await _nativeService.imGetCaptcha(
        _phoneController.text,
        type: 'SMS',           // CaptchaType: SMS=短信
        scene: 'register',     // 使用场景: 注册
      );
      
      EasyLoading.dismiss();
      
      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误';
      
      if (errorCode == 0) {
        // 保存 captcha_id（从返回的 data 中解析）
        final data = result['data'];
        if (data != null && data.isNotEmpty) {
          // data 应该是 JSON 字符串，解析它
          try {
            final dataMap = json.decode(data);
            _captchaId = dataMap['captcha_id'];
            print('✅ 获取到 captcha_id: $_captchaId');
          } catch (e) {
            print('⚠️ 解析 captcha_id 失败: $e');
          }
        }
        
        EasyLoading.showSuccess('验证码已发送');
        
        // 开始倒计时
        setState(() {
          _countdown = 60;
        });
        
        _startCountdown();
      } else {
        EasyLoading.showError('发送失败: $message (code: $errorCode)');
      }
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('发送失败: $e');
    }
  }

  /// 手机验证码倒计时
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  /// 获取邮箱验证码
  void _getEmailVerifyCode() async {
    // 验证邮箱
    if (_emailController.text.isEmpty) {
      EasyLoading.showError('请先输入邮箱');
      return;
    }
    
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(_emailController.text)) {
      EasyLoading.showError('请输入正确的邮箱地址');
      return;
    }
    
    try {
      EasyLoading.show(status: '发送中...');
      
      // 调用 Native 获取邮箱验证码接口
      final result = await _nativeService.imGetCaptcha(
        _emailController.text,
        type: 'EMAIL',         // CaptchaType: EMAIL=邮箱
        scene: 'register',     // 使用场景: 注册
      );
      
      EasyLoading.dismiss();
      
      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误';
      
      if (errorCode == 0) {
        // 保存 captcha_id
        final data = result['data'];
        if (data != null && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data);
            _emailCaptchaId = dataMap['captcha_id'];
            print('✅ 获取到邮箱 captcha_id: $_emailCaptchaId');
          } catch (e) {
            print('⚠️ 解析邮箱 captcha_id 失败: $e');
          }
        }
        
        EasyLoading.showSuccess('验证码已发送到邮箱');
        
        // 开始倒计时
        setState(() {
          _emailCountdown = 60;
        });
        
        _startEmailCountdown();
      } else {
        EasyLoading.showError('发送失败: $message (code: $errorCode)');
      }
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('发送失败: $e');
    }
  }

  /// 邮箱验证码倒计时
  void _startEmailCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_emailCountdown > 0) {
        setState(() {
          _emailCountdown--;
        });
        _startEmailCountdown();
      }
    });
  }

  /// 处理注册
  void _handleRegister() async {
    // 验证用户协议
    if (!_agreeTerms) {
      EasyLoading.showError('请先阅读并同意用户协议');
      return;
    }
    
    // 表单验证
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      EasyLoading.show(status: '注册中...');
      
      // 构建注册数据
      Map<String, dynamic> registerData = {};
      
      if (_registerType == RegisterType.accountPassword) {
        // 账号密码注册
        registerData = {
          'register_type': 'account', // 注册方式：账号
          'account_id': _accountController.text,
          'password': _passwordController.text,
        };
        
        // 添加邀请码（如果有）
        if (_inviteCodeController.text.isNotEmpty) {
          registerData['biz_code'] = _inviteCodeController.text;
        }
        
      } else if (_registerType == RegisterType.phoneCode) {
        // 手机验证码注册
        registerData = {
          'register_type': 'phone', // 注册方式：手机
          'phone': _phoneController.text,
          'password': _passwordController.text,
        };
        
        // 添加验证码信息（如果有 captcha_id）
        if (_captchaId != null && _verifyCodeController.text.isNotEmpty) {
          registerData['captcha'] = {
            'captcha_id': _captchaId,
            'answer': _verifyCodeController.text,
          };
        }
        
        // 添加邀请码（如果有）
        if (_inviteCodeController.text.isNotEmpty) {
          registerData['biz_code'] = _inviteCodeController.text;
        }
      } else if (_registerType == RegisterType.emailCode) {
        // 邮箱验证码注册
        registerData = {
          'account_id': _emailController.text,
          'register_type': 'email', // 注册方式：邮箱
          'email': _emailController.text,
          'password': _passwordController.text,
        };
        
        // 添加验证码信息（如果有 captcha_id）
        if (_emailCaptchaId != null && _emailVerifyCodeController.text.isNotEmpty) {
          registerData['captcha'] = {
            'captcha_id': _emailCaptchaId,
            'answer': _emailVerifyCodeController.text,
          };
        }
        
        // 添加邀请码（如果有）
        if (_inviteCodeController.text.isNotEmpty) {
          registerData['biz_code'] = _inviteCodeController.text;
        }

        // 输出邮箱验证吗注册的参数
        print('📝 邮箱验证码注册的参数: $_emailCaptchaId');
        print('📝 邮箱验证码注册的参数: ${_emailVerifyCodeController.text}');
        print('📝 邮箱验证码注册的参数: $registerData');
        print('📝 邮箱验证码注册的参数: ${registerData['captcha']}');
        print('📝 邮箱验证码注册的参数: ${registerData['captcha']['captcha_id']}');
        print('📝 邮箱验证码注册的参数: ${registerData['captcha']['answer']}');
      }
      
      print('📝 注册数据: $registerData');
      
      // 调用 Native 注册接口
      final result = await _nativeService.imRegister(registerData);
      
      EasyLoading.dismiss();
      
      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误';
      final data = result['data'] ?? '';
      
      print('📊 注册结果: errorCode=$errorCode, message=$message, data=$data');
      
      if (errorCode == 0) {
        // 解析返回的数据
        if (data != null && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            
            // 获取 token
            final token = dataMap['token'] as String?;
            final refresh_token = dataMap['refresh_token'] as String?;
            
            // 获取用户信息
            final userMap = dataMap['user'] as Map<String, dynamic>?;
            
            if (token != null && userMap != null) {
              // 创建用户模型
              final user = UserModel.fromJson(userMap);
              
              // 保存登录信息到 GlobalController
              final globalController = Get.find<GlobalController>();
              await globalController.saveLoginInfo(token, refresh_token ?? '', user);
              
              print('✅ 注册成功，用户信息已保存: ${user.nickname}');
              
              // 使用 Token 自动登录，确保 SDK 状态正确
              EasyLoading.show(status: '正在登录...');
              print('🔐 注册后使用 Token 自动登录...');
              
              final loginSuccess = await globalController.autoLoginWithToken();
              EasyLoading.dismiss();
              
              if (loginSuccess) {
                print('✅ Token 自动登录成功');
                EasyLoading.showSuccess('注册成功');
                
                // 延迟后跳转到首页
                await Future.delayed(const Duration(milliseconds: 800));
                Get.offAllNamed('/home');
              } else {
                print('⚠️ Token 自动登录失败，仍跳转到首页');
                EasyLoading.showSuccess('注册成功');
                await Future.delayed(const Duration(milliseconds: 800));
                Get.offAllNamed('/home');
              }
              return;
            }
          } catch (e) {
            print('⚠️ 解析注册返回数据失败: $e');
          }
        }
        
        // 如果解析失败，仍然提示成功并返回登录页
        EasyLoading.showSuccess('注册成功，请登录');
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.back();
      } else {
        EasyLoading.showError('注册失败: $message (code: $errorCode)');
      }
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('注册失败: $e');
      print('❌ 注册异常: $e');
    }
  }
}

