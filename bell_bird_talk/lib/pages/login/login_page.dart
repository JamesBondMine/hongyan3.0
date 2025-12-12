import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../settings/language_page.dart';
import '../settings/reset_password_page.dart';

/// 登录页面
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

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
          child: Stack(
            children: [
              // 主内容
              Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 和标题
                  _buildHeader(),
                  
                      const SizedBox(height: 40),
                  
                  // 登录表单
                  _buildLoginForm(controller),
                  
                      const SizedBox(height: 24),
                  
                  // 其他操作
                  _buildFooter(),
                ],
              ),
            ),
              ),
              
              // 右上角语言切换按钮
              Positioned(
                top: 8,
                right: 8,
                child: _buildLanguageButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建语言切换按钮
  Widget _buildLanguageButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(() => const LanguagePage());
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 4),
              const Text(
                '语言',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
  
        
        // 标题
        const Text(
          '铃鸟聊天',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 副标题
        Text(
          '欢迎回来',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(LoginController controller) {
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
        children: [
          // 登录方式切换 Tab
          _buildLoginTypeTabs(controller),
          
          const SizedBox(height: 24),
          
          // 登录表单内容（根据登录方式显示不同内容）
          Obx(() => _buildLoginFormContent(controller)),
          
          const SizedBox(height: 24),
          
          // 登录按钮
          _buildLoginButton(controller),
          
          const SizedBox(height: 16),
          
          // 注册按钮
          _buildRegisterButton(),
        ],
      ),
    );
  }
  
  /// 构建登录方式切换 Tab
  Widget _buildLoginTypeTabs(LoginController controller) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(
            title: '邮箱登录',
            isSelected: controller.loginType.value == LoginType.emailCode,
            onTap: () => controller.switchLoginType(LoginType.emailCode),
          ),
          _buildTabItem(
            title: '手机登录',
            isSelected: controller.loginType.value == LoginType.smsCode,
            onTap: () => controller.switchLoginType(LoginType.smsCode),
          ),
          _buildTabItem(
            title: '密码登录',
            isSelected: controller.loginType.value == LoginType.password,
            onTap: () => controller.switchLoginType(LoginType.password),
          ),
        ],
      ),
    ));
  }
  
  /// 构建单个 Tab 项
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
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建登录表单内容
  Widget _buildLoginFormContent(LoginController controller) {
    switch (controller.loginType.value) {
      case LoginType.password:
        return _buildPasswordLoginForm(controller);
      case LoginType.smsCode:
        return _buildSMSLoginForm(controller);
      case LoginType.emailCode:
        return _buildEmailLoginForm(controller);
    }
  }
  
  /// 密码登录表单
  Widget _buildPasswordLoginForm(LoginController controller) {
    return Column(
        children: [
          // 用户名输入框
          TextField(
            controller: controller.usernameController,
            decoration: InputDecoration(
            labelText: '账号',
            hintText: '请输入账号',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 密码输入框
          Obx(() => TextField(
            controller: controller.passwordController,
            obscureText: controller.obscurePassword.value,
            decoration: InputDecoration(
              labelText: '密码',
            hintText: '请输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          )),
          
          const SizedBox(height: 12),
          
          // 记住密码
          Row(
            children: [
              Obx(() => Checkbox(
                value: controller.rememberPassword.value,
                onChanged: (value) {
                  controller.rememberPassword.value = value ?? false;
                },
              )),
              const Text('记住密码'),
              const Spacer(),
              TextButton(
                onPressed: () {
                Get.to(() => const ForgotPasswordPage());
                },
                child: const Text('忘记密码？'),
              ),
            ],
          ),
        // 邀请码输入框
        _buildInviteCodeInput(controller),
      ],
    );
  }
  
  /// 短信登录表单（支持密码/验证码模式切换）
  Widget _buildSMSLoginForm(LoginController controller) {
    return Obx(() => Column(
      children: [
        // 手机号输入框
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: '手机号',
            hintText: '请输入手机号',
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
          
        const SizedBox(height: 16),
        
        // 根据模式显示密码或验证码
        if (controller.smsUsePassword.value) ...[
          // 密码输入框
          TextField(
            controller: controller.passwordController,
            obscureText: controller.obscurePassword.value,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ] else ...[
          // 验证码输入框 + 发送按钮
          _buildCodeInputRow(controller),
        ],
        
        const SizedBox(height: 8),
        
        // 模式切换和忘记密码
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧：模式切换
            TextButton(
              onPressed: controller.toggleSmsLoginMode,
              child: Text(
                controller.smsUsePassword.value ? '验证码登录' : '密码登录',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 13,
                ),
              ),
            ),
            // 右侧：忘记密码（仅在密码登录模式下显示）
            if (controller.smsUsePassword.value)
              TextButton(
                onPressed: () {
                  Get.to(() => const ResetPasswordPage());
                },
                child: Text(
                  '忘记密码',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 邀请码输入框
        _buildInviteCodeInput(controller),
      ],
    ));
  }
  
  /// 邮箱登录表单（支持密码/验证码模式切换）
  Widget _buildEmailLoginForm(LoginController controller) {
    return Obx(() => Column(
      children: [
        // 邮箱输入框
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: '邮箱',
            hintText: '请输入邮箱地址',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 根据模式显示密码或验证码
        if (controller.emailUsePassword.value) ...[
          // 密码输入框
          TextField(
            controller: controller.passwordController,
            obscureText: controller.obscurePassword.value,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ] else ...[
          // 验证码输入框 + 发送按钮
          _buildCodeInputRow(controller),
        ],
        
        const SizedBox(height: 8),
        
        // 模式切换和忘记密码
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧：模式切换
            TextButton(
              onPressed: controller.toggleEmailLoginMode,
              child: Text(
                controller.emailUsePassword.value ? '验证码登录' : '密码登录',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 13,
                ),
              ),
            ),
            // 右侧：忘记密码（仅在密码登录模式下显示）
            if (controller.emailUsePassword.value)
              TextButton(
                onPressed: () {
                  Get.to(() => const ResetPasswordPage());
                },
                child: Text(
                  '忘记密码',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 邀请码输入框
        _buildInviteCodeInput(controller),
      ],
    ));
  }
  
  /// 邀请码输入框
  Widget _buildInviteCodeInput(LoginController controller) {
    return TextField(
      controller: controller.inviteCodeController,
      decoration: InputDecoration(
        labelText: '邀请码',
        hintText: '请输入邀请码（选填）',
        prefixIcon: const Icon(Icons.card_giftcard_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
  
  /// 验证码输入行（验证码输入框 + 发送按钮）
  Widget _buildCodeInputRow(LoginController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.codeController,
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
          Obx(() => SizedBox(
          width: 110,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.countdown.value > 0 || controller.isSendingCode.value
                ? null
                : controller.sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: controller.isSendingCode.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    controller.countdown.value > 0
                        ? '${controller.countdown.value}s'
                        : '获取验证码',
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        )),
      ],
    );
  }
  
  /// 登录按钮
  Widget _buildLoginButton(LoginController controller) {
    return Obx(() => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
    ));
  }
  
  /// 注册按钮
  Widget _buildRegisterButton() {
    return SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Get.to(() => const RegisterPage());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '注册账号',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 构建底部
  Widget _buildFooter() {
    return Column(
      children: [
        // 提示信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '登录说明',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持账号密码、短信验证码、邮箱验证码三种登录方式',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
