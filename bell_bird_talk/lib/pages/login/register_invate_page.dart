import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:bell_bird_talk/pages/login/register_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class RegisterInvatePage extends StatefulWidget {
  const RegisterInvatePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return RegisterInvatePageState();
  }
}

class RegisterInvatePageState extends State<RegisterInvatePage> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

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
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 32,
              ),
              child: ListView(
                padding: EdgeInsets.all(0),
                children: [
                  _buildAppBar(),
                  SizedBox(height: 18),
                  _buildHeader(),
                  SizedBox(height: 30),
                  _buildInviteCodeInput(controller),
                  SizedBox(height: 26),
                  CommonButton(
                    text: '下一步'.tr,
                    enabled: controller.inviteCodeController.text.isNotEmpty,
                    onPressed: () {
                      if (controller.inviteCodeController.text.isEmpty) {
                        EasyLoading.showError('请输入邀请码'.tr);
                        return;
                      }
                      Get.to(
                        () => RegisterPage(
                          invateCode: controller.inviteCodeController.text,
                        ),
                      );
                    },
                  ),
                  Spacer(),
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 登录按钮
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: () {
          Get.offAll(() => const LoginPage());
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
              '已有账号?'.tr,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '去登录'.tr,
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

  /// 顶部导航栏
  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.start,
    );
  }

  /// 邀请码输入框
  Widget _buildInviteCodeInput(LoginController controller) {
    return LoginTextField(
      controller: controller.inviteCodeController,
      title: '邀请码/邀请链接'.tr,
      hintText: '请输入邀请码'.tr,
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {});
        }
      },
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
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

          const SizedBox(height: 16),

          // 标题
          Text(
            '注册'.tr,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          // 副标题
          Text(
            '请输入邀请码/邀请链接加入企业'.tr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
