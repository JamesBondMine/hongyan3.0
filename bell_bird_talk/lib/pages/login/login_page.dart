import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/utils/app_colors.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_page.dart';
import '../settings/language_page.dart';
import '../settings/reset_password_page.dart';
import 'country_code_page.dart';

/// 登录页面
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColors.lightBackgroundPrimary ,
      body: Stack(
        children: [
          Image.asset(
            'assets/img/login/loginbgsmall.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // 主内容
          SafeArea(
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
        ],
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
    return SizedBox(
      width: Get.width,
      child:  Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
      children: [
        // Logo
        Container(
          width: 60,
          height: 60,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // color: Colors.white,
          ),
          child:  Image.asset(
              'assets/img/logo/logo.png',
              fit: BoxFit.contain,
            ),
          
        ),

        const SizedBox(height: 16),

        // 标题
        const Text(
          '登录',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 8),

        // 副标题
        Text(
          '请输入手机号/邮箱',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
      ],
    ));
  }

  /// 构建登录表单
  Widget _buildLoginForm(LoginController controller) {
    return Container(
      // padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        // color: Colors.white,
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
            title: '手机登录',
            isSelected: controller.loginType.value == LoginType.smsCode,
            onTap: () => controller.switchLoginType(LoginType.smsCode),
          ),
          _buildTabItem(
            title: '邮箱登录',
            isSelected: controller.loginType.value == LoginType.emailCode,
            onTap: () => controller.switchLoginType(LoginType.emailCode),
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
      case LoginType.smsCode:
        return _buildSMSLoginForm(controller);
      case LoginType.emailCode:
        return _buildEmailLoginForm(controller);
      default:
        // 默认使用手机登录
        return _buildSMSLoginForm(controller);
    }
  }
  
  /// 短信登录表单（支持密码/验证码模式切换）
  Widget _buildSMSLoginForm(LoginController controller) {
    return Obx(() => Column(
      children: [
        // 手机号输入框
        LoginTextField(
          controller: controller.phoneController,
          title: '手机号',
          hintText: '请输入手机号',
          keyboardType: TextInputType.phone,
          prefixIcon: InkWell(
            onTap: () => showModalBottomSheet(
              context: Get.context!,
              builder: (context) => const CountryCodePage(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(controller.selectedFlag.value, style: const TextStyle(fontSize: 18))),
                  const SizedBox(width: 4),
                  Obx(() => Text(controller.selectedCountryCode.value, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
          
        const SizedBox(height: 16),
        
        // 根据模式显示密码或验证码
        if (controller.smsUsePassword.value) ...[
          // 密码输入框
          LoginTextField(
            controller: controller.passwordController,
            title: '密码',
            hintText: '请输入密码',
            obscureText: controller.obscurePassword.value,
            // prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ] else ...[
          // 验证码输入框 + 发送按钮
          _buildCodeInputRow(controller),
        ],
        
        
        
        const SizedBox(height: 16),
        
        // 邀请码输入框
        _buildInviteCodeInput(controller),
        const SizedBox(height: 8),
        
        // 模式切换和忘记密码
        _changeLoginTypeView(controller),
      ],
    ));
  }

  // 
  Widget _changeLoginTypeView( LoginController controller) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧：模式切换
            TextButton(
            onPressed: controller.toggleSmsLoginMode,
            child: Text(
              controller.smsUsePassword.value ? '验证码登录' : '密码登录',
              style: TextStyle(
                color: AppColors.textTapPrimary,
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
                    color: AppColors.textTapPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        );
  }
  
  /// 邮箱登录表单（支持密码/验证码模式切换）
  Widget _buildEmailLoginForm(LoginController controller) {
    return Obx(() => Column(
      children: [
        // 邮箱输入框
        LoginTextField(
          controller: controller.emailController,
          title: '邮箱',
          hintText: '请输入邮箱地址',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        
        const SizedBox(height: 16),
        
        // 根据模式显示密码或验证码
        if (controller.emailUsePassword.value) ...[
          // 密码输入框
          LoginTextField(
            controller: controller.passwordController,
            title: '密码',
            hintText: '请输入密码',
            obscureText: controller.obscurePassword.value,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: controller.togglePasswordVisibility,
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
                color: AppColors.textTapPrimary,
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
                    color: AppColors.textTapPrimary,
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
    return LoginTextField(
      controller: controller.inviteCodeController,
      title: '邀请码',
      hintText: '请输入邀请码（选填）',
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    );
  }
  
  /// 验证码输入行（验证码输入框 + 发送按钮）
  Widget _buildCodeInputRow(LoginController controller) {
    return LoginTextField(
      controller: controller.codeController,
      title: '验证码',
      keyboardType: TextInputType.number,
      maxLength: 6,
      hintText: '请输入验证码',
      trailingWidget: Obx(() => Container(
        margin: const EdgeInsets.only(right: 8),
        child: TextButton(
          onPressed: controller.countdown.value > 0 || controller.isSendingCode.value
              ? null
              : controller.sendVerificationCode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: controller.isSendingCode.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : Text(
                  controller.countdown.value > 0
                      ? '${controller.countdown.value}s'
                      : '获取验证码',
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.countdown.value > 0 || controller.isSendingCode.value
                        ? Colors.grey
                        : Colors.blue,
                  ),
                ),
        ),
      )),
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
      child: TextButton(
        onPressed: () {
          Get.to(() => const RegisterPage());
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '还没有账号?',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '去注册',
              style: TextStyle(
                color: AppColors.textTapPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
