

import 'dart:convert';

import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/register_pwd_page.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

// ignore: must_be_immutable
class RegisterCodePage extends StatefulWidget {
  RegisterCodePage({super.key,  required this.isForget, required this.cid, this.registerType = RegisterType.phoneCode, this.account = '', this.invateCode = ''});
  // 分为注册和忘记密码两种模式
  bool isForget = false;
  RegisterType registerType = RegisterType.phoneCode;
  String account = '';
  String invateCode = '';
  String cid = '';
  
  
  @override
  State<StatefulWidget> createState() {
    return RegisterCodePageState();
  }

}
class RegisterCodePageState extends State<RegisterCodePage> {

  final _nativeService = IOSNativeService();

  // 验证码ID
  String _cid = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _cid = widget.cid;

    print('isForget: ${widget.isForget}' );
  }

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
              _buildCountDown(controller),
              SizedBox(height: 10),
              CommonButton(
                text: '确定',
                enabled: controller.codeController.text.isNotEmpty,
                onPressed: () {
                  Get.to(() =>  RegisterPwdPage(cid: _cid, registerType: widget.registerType, account: widget.account,code: controller.codeController.text, invateCode: widget.invateCode,isForget: widget.isForget,));
                },
              ),
            ],)))]));

  }

  // 倒计时视图
  Widget _buildCountDown(LoginController controller) {
    return  GestureDetector(onTap: () {
      _getCode(controller);
    },
    child: Row(children: [Padding(padding: EdgeInsetsGeometry.all(10), child: Text(
          '59秒后重新获取',
          style: TextStyle(
            fontSize: 14,
            color: GbsColors.textPrimary,
          ),),
        ),],),);
  }

  // 获取验证码的方法
  void _getCode(LoginController controller) async {
    if (widget.isForget) {
      await controller.sendForgetVerificationCode((cid) {});
    } else {
      _getVerifyCode(() {
        
      });
    }
  }

   /// 获取验证码
  void _getVerifyCode(VoidCallback onVerifyCodeSuccess) async {

    try {
      EasyLoading.show(status: '发送中...');
      
      // 调用 Native 获取短信验证码接口
      final result = await _nativeService.imGetCaptcha(
        widget.account,
        type: widget.registerType == RegisterType.phoneCode ? 'SMS' : 'EMAIL',           // CaptchaType: SMS=短信
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
            String captchaId = dataMap['captcha_id'];
            print('✅ 获取到 captcha_id: $captchaId');
          } catch (e) {
            print('⚠️ 解析 captcha_id 失败: $e');
          }
        }
        
        EasyLoading.showSuccess('验证码已发送');
        onVerifyCodeSuccess();
      } else {
        EasyLoading.showError('发送失败: $message (code: $errorCode)');
      }
      
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('发送失败: $e');
    }
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
    onChanged: (value) {
      if (mounted) {
        setState(() {
        controller.codeController.text = value;
      });
      }
    },
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
        Text(
          widget.isForget ? '忘记密码' : '注册',
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