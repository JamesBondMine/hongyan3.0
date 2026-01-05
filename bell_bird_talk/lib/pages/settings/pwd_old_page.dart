
import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/settings/change_password_page.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PwdOldPage extends StatefulWidget {
  const PwdOldPage({super.key});

  @override
  State<PwdOldPage> createState() => _PwdOldPageState();
  
}

class _PwdOldPageState extends State<PwdOldPage> {

  final controller = Get.put(LoginController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('修改密码'),
      ),
      body: Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child: Column(children: [
        _buildInviteCodeInput(controller),
        SizedBox(height: 26),
        CommonButton(text: '下一步',
          enabled: controller.oldPasswordController.text.isNotEmpty,
          onPressed: () {
            if (controller.oldPasswordController.text.isEmpty) {
              // EasyLoading.showError('请输入邀请码');
              return;
            }
            Get.to(() => ChangePasswordPage(oldPwd: controller.oldPasswordController.text));
          },
        ),
      ],)  ),
    );
  }

  /// 邀请码输入框
  Widget _buildInviteCodeInput(LoginController controller) {
    return LoginTextField(
      controller: controller.oldPasswordController,
      title: '原密码',
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
}