

import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/register_pwd_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class RegisterCodePage extends StatefulWidget {
  RegisterCodePage({super.key, this.registerType = RegisterType.phoneCode, this.account = '', this.invateCode = '', isForget = false});
  
  RegisterType registerType = RegisterType.phoneCode;
  String account = '';
  String invateCode = '';
  // 分为注册和忘记密码两种模式
  bool isForget = false;
  
  @override
  State<StatefulWidget> createState() {
    return RegisterCodePageState();
  }

}
class RegisterCodePageState extends State<RegisterCodePage> {

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA ,
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
            child:SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
                    child: Column(children: [
                      _buildAppBar(),
                      // SizedBox(height: 18),
              _buildHeader(),
              // SizedBox(height: 16),
              _buildInviteCodeInput(controller),
              Row(children: [Padding(padding: EdgeInsetsGeometry.all(10), child: Text(
          '59秒后重新获取',
          style: TextStyle(
            fontSize: 14,
            color: GbsColors.textPrimary,
          ),),
        ),],),
              SizedBox(height: 10),
              CommonButton(
                text: '确定',
                enabled: controller.inviteCodeController.text.isNotEmpty,
                onPressed: () {
                  Get.to(() =>  RegisterPwdPage(registerType: widget.registerType, account: widget.account,code: controller.inviteCodeController.text, invateCode: widget.invateCode));
                },
              ),
            ],)))]));

  }

  /// 顶部导航栏
  Widget _buildAppBar() {
    return  Row(
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
    return Pinput(
      length: 6,
      defaultPinTheme: PinTheme(
        width: 50,
        height: 60,
        textStyle: const TextStyle(fontSize: 20, color: Colors.black),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    onCompleted: (pin) => print(pin),
  );
  }



  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(bottom: 20),
      width: Get.width,
      child:  Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
      children: [
        const SizedBox(height: 16),

        // 标题
        const Text(
          '注册',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 28),

        // 副标题
        Text(
          '验证码已发送至',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
         Text(
          widget.account,
          style: TextStyle(
            fontSize: 20,
            color: GbsColors.titleColor,
          ),
        ),
      ],
    ));
  }

}