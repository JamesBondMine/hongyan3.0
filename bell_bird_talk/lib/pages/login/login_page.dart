import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/register_code_page.dart';
import 'package:bell_bird_talk/pages/login/register_invate_page.dart';
import 'package:bell_bird_talk/pages/login/register_pwd_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../settings/language_page.dart';
import 'country_code_page.dart';

/// 登录页面
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // 表单更新触发器（用于响应式更新按钮状态）
  static final RxInt _formUpdateTrigger = 0.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    // 监听登录类型和模式变化，触发按钮状态更新
    ever(controller.loginType, (_) => _formUpdateTrigger.value++);
    ever(controller.smsUsePassword, (_) => _formUpdateTrigger.value++);
    ever(controller.emailUsePassword, (_) => _formUpdateTrigger.value++);

    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
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

                        SizedBox(height: 30.h),

                        // 登录表单x
                        _buildLoginForm(controller),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),

                // 右上角语言切换按钮
                Positioned(top: 8, right: 8, child: _buildLanguageButton()),
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
              Icon(Icons.language, color: Colors.white, size: 22.sp),
              SizedBox(width: 4.w),
              Text(
                '语言'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // color: Colors.white,
            ),
            child: Image.asset('assets/img/logo/logo.png', fit: BoxFit.contain),
          ),

          SizedBox(height: 22.h),

          // 标题
          Text(
            '登录'.tr,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // 副标题
          Text(
            '请输入手机号/邮箱'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm(LoginController controller) {
    return Column(
      children: [
        // 登录方式切换 Tab
        _buildLoginTypeTabs(controller),
        SizedBox(height: 24.h),
        // 登录表单内容（根据登录方式显示不同内容）
        Obx(() => _buildLoginFormContent(controller)),
        // 登录按钮
        _buildLoginButton(controller),
        SizedBox(height: 60.h),
        // 注册按钮
        _buildRegisterButton(),
      ],
    );
  }

  /// 构建登录方式切换 Tab
  Widget _buildLoginTypeTabs(LoginController controller) {
    return Obx(
      () => Container(
        height: 36,
        decoration: BoxDecoration(
          color: Color(0xFF1D61E7).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            _buildTabItem(
              title: '手机登录'.tr,
              isSelected: controller.loginType.value == LoginType.smsCode,
              onTap: () => controller.switchLoginType(LoginType.smsCode),
            ),
            _buildTabItem(
              title: '邮箱登录'.tr,
              isSelected: controller.loginType.value == LoginType.emailCode,
              onTap: () => controller.switchLoginType(LoginType.emailCode),
            ),
          ],
        ),
      ),
    );
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
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
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
    return Obx(
      () => Column(
        children: [
          // 手机号输入框
          LoginTextField(
            controller: controller.phoneController,
            title: '手机号'.tr,
            hintText: '请输入手机号'.tr,
            keyboardType: TextInputType.phone,
            onChanged: _onInputChanged(),
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
                    Obx(
                      () => Text(
                        controller.selectedFlag.value,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Obx(
                      () => Text(
                        controller.selectedCountryCode.value,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
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
              title: '密码'.tr,
              hintText: '请输入密码'.tr,
              obscureText: controller.obscurePassword.value,
              onChanged: _onInputChanged(),
              // prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Image.asset(
                  controller.obscurePassword.value
                      ? 'assets/img/login/eyeoff.png'
                      : 'assets/img/login/eye.png',
                  width: 20,
                  height: 20,
                  color: controller.obscurePassword.value
                      ? Colors.grey
                      : Colors.blue,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ] else ...[
            // 验证码输入框 + 发送按钮
            _buildCodeInputRow(controller),
          ],

          SizedBox(height: 16.h),

          // 邀请码输入框
          _buildInviteCodeInput(controller),
          // const SizedBox(height: 8),

          // 模式切换和忘记密码
          _changeLoginTypeView(controller),
        ],
      ),
    );
  }

  //
  Widget _changeLoginTypeView(LoginController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧：模式切换
        TextButton(
          onPressed: controller.toggleSmsLoginMode,
          child: Text(
            controller.smsUsePassword.value ? '验证码登录'.tr : '密码登录'.tr,
            style: TextStyle(color: GbsColors.lightDesPrimary, fontSize: 13.sp),
          ),
        ),
        // 右侧：忘记密码（仅在密码登录模式下显示）
        if (controller.smsUsePassword.value)
          TextButton(
            onPressed: () {
              // Get.to(() => const ResetPasswordPage());
              if (controller.phoneController.text.isEmpty) {
                EasyLoading.showError('请输入邮箱地址'.tr);
                return;
              }
              // 发验证码
              controller.sendForgetVerificationCode((cid) {
                Get.to(
                  () => RegisterCodePage(
                    cid: cid,
                    registerType:
                        controller.loginType.value == LoginType.smsCode
                        ? RegisterType.phoneCode
                        : RegisterType.emailCode,
                    account: controller.loginType.value == LoginType.smsCode
                        ? controller.phoneController.text
                        : controller.emailController.text,
                    isForget: true,
                  ),
                );
              });
            },
            child: Text(
              '忘记密码'.tr,
              style: TextStyle(color: GbsColors.textPrimary, fontSize: 13.sp),
            ),
          ),
      ],
    );
  }

  /// 邮箱登录表单（支持密码/验证码模式切换）
  Widget _buildEmailLoginForm(LoginController controller) {
    return Obx(
      () => Column(
        children: [
          // 邮箱输入框
          LoginTextField(
            controller: controller.emailController,
            title: '邮箱'.tr,
            hintText: '请输入邮箱地址'.tr,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            onChanged: _onInputChanged(),
          ),

          SizedBox(height: 16.h),

          // 根据模式显示密码或验证码
          if (controller.emailUsePassword.value) ...[
            // 密码输入框
            LoginTextField(
              controller: controller.passwordController,
              title: '密码'.tr,
              hintText: '请输入密码'.tr,
              obscureText: controller.obscurePassword.value,
              onChanged: _onInputChanged(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon:
              
               IconButton(
                icon: Image.asset(
                  controller.obscurePassword.value
                      ? 'assets/img/login/eyeoff.png'
                      : 'assets/img/login/eye.png',
                  width: 20.w,
                  height: 20.h,
                  color: controller.obscurePassword.value
                      ? Colors.grey
                      : Colors.blue,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ] else ...[
            // 验证码输入框 + 发送按钮
            _buildCodeInputRow(controller),
          ],

          SizedBox(height: 16.h),

          // 邀请码输入框
          _buildInviteCodeInput(controller),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧：模式切换
              TextButton(
                onPressed: controller.toggleEmailLoginMode,
                child: Text(
                  controller.emailUsePassword.value ? '验证码登录'.tr : '密码登录'.tr,
                  style: TextStyle(color: GbsColors.textPrimary, fontSize: 13),
                ),
              ),
              // 右侧：忘记密码（仅在密码登录模式下显示）
              if (controller.emailUsePassword.value)
                TextButton(
                  onPressed: () {
                    // Get.to(() => const ResetPasswordPage());
                    if (controller.emailController.text.isEmpty) {
                      EasyLoading.showError('请输入邮箱地址'.tr);
                      return;
                    }
                    controller.sendForgetVerificationCode((cid) {
                      Get.to(
                        () => RegisterCodePage(
                          cid: cid,
                          registerType:
                              controller.loginType.value == LoginType.smsCode
                              ? RegisterType.phoneCode
                              : RegisterType.emailCode,
                          account:
                              controller.loginType.value == LoginType.smsCode
                              ? controller.phoneController.text
                              : controller.emailController.text,
                          isForget: true,
                        ),
                      );
                    });
                  },
                  child: Text(
                    '忘记密码'.tr,
                    style: TextStyle(
                      color: GbsColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 邀请码输入框
  Widget _buildInviteCodeInput(LoginController controller) {
    return LoginTextField(
      controller: controller.inviteCodeController,
      title: '邀请码'.tr,
      hintText: '请输入邀请码'.tr,
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    );
  }

  /// 验证码输入行（验证码输入框 + 发送按钮）
  Widget _buildCodeInputRow(LoginController controller) {
    return LoginTextField(
      controller: controller.codeController,
      title: '验证码'.tr,
      keyboardType: TextInputType.number,
      maxLength: 6,
      hintText: '请输入验证码'.tr,
      onChanged: _onInputChanged(),
      trailingWidget: Obx(
        () => Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed:
                controller.countdown.value > 0 || controller.isSendingCode.value
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
                ?  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : Text(
                    controller.countdown.value > 0
                        ? '${controller.countdown.value}s'
                        : '获取验证码'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color:
                          controller.countdown.value > 0 ||
                              controller.isSendingCode.value
                          ? Colors.grey
                          : Colors.blue,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// 登录按钮
  Widget _buildLoginButton(LoginController controller) {
    return Obx(() {
      // 触发表单验证（响应 _formUpdateTrigger 的变化）
      _formUpdateTrigger.value;

      // 判断按钮是否启用：根据登录类型和模式检查必填字段
      final isEnabled = _isFormValid(controller);

      return CommonButton(
        text: '登录'.tr,
        enabled: isEnabled,
        isLoading: controller.isLoading.value,
        onPressed: controller.login,
      );
    });
  }

  /// 创建输入框变化回调（用于更新按钮状态）
  void Function(String) _onInputChanged() {
    return (_) => _formUpdateTrigger.value++;
  }

  /// 检查表单是否有效
  bool _isFormValid(LoginController controller) {

    switch (controller.loginType.value) {
      case LoginType.smsCode:
        // 手机登录
        final phone = controller.phoneController.text.trim();
        if (phone.isEmpty) return false;

        if (controller.smsUsePassword.value) {
          // 密码模式：需要手机号和密码
          final password = controller.passwordController.text.trim();
          return password.isNotEmpty;
        } else {
          // 验证码模式：需要手机号和验证码
          final code = controller.codeController.text.trim();
          return code.isNotEmpty;
        }

      case LoginType.emailCode:
        // 邮箱登录
        final email = controller.emailController.text.trim();
        if (email.isEmpty) return false;

        if (controller.emailUsePassword.value) {
          // 密码模式：需要邮箱和密码
          final password = controller.passwordController.text.trim();
          return password.isNotEmpty;
        } else {
          // 验证码模式：需要邮箱和验证码
          final code = controller.codeController.text.trim();
          return code.isNotEmpty;
        }

      default:
        return false;
    }
  }

  /// 注册按钮
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: () {
          Get.to(() => const RegisterInvatePage());
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
              '还没有账号?'.tr,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '去注册'.tr,
              style: TextStyle(
                color: GbsColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
