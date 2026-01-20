import 'dart:convert';
import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/country_code_page.dart';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:bell_bird_talk/pages/login/register_code_page.dart';
import 'package:bell_bird_talk/pages/login/register_pwd_page.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 注册页面
class RegisterPage extends StatefulWidget {
  RegisterPage({super.key, this.invateCode = ''});

  String invateCode = '';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(); // 修改为 TextEditingController
  final _emailController = TextEditingController();
  final _nativeService = IOSNativeService();

  // 添加国家代码相关的变量
  String _selectedCountryCode = '+86';
  String _selectedFlag = '🇨🇳';

  String? _captchaId; // 存储手机验证码 ID
  String? _emailCaptchaId; // 存储邮箱验证码 ID
  RegisterType _registerType = RegisterType.phoneCode; // 默认手机验证码注册

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                // 顶部导航栏
                _buildAppBar(),
                // 表单内容
                Expanded(
                  child: Padding(
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
                        Spacer(),

                        _buildLoginButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      width: Get.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
        children: [
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
            '请输入手机号/邮箱'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 注册方式切换
  Widget _buildRegisterTypeSwitch() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF1D61E7).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              title: '手机号'.tr,
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
              title: '邮箱'.tr,
              isSelected: _registerType == RegisterType.emailCode,
              onTap: () {
                setState(() {
                  _registerType = RegisterType.emailCode;
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
        height: 32,
        alignment: Alignment.center,
        // padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? GbsColors.titleColor : GbsColors.des9Color,
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
        // padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据注册类型显示不同字段
            if (_registerType == RegisterType.phoneCode) ...[
              LoginTextField(
                controller: _phoneController,
                title: '手机号'.tr,
                hintText: '请输入手机号'.tr,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  // 处理手机号变化
                  if (mounted) {
                    setState(() {});
                  }
                },
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
                        Text(
                          _selectedFlag,
                          style: const TextStyle(fontSize: 18),
                        ), // 修改
                        const SizedBox(width: 4),
                        Text(
                          _selectedCountryCode,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ), // 修改
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),

              // const SizedBox(height: 10),/
            ] else if (_registerType == RegisterType.emailCode) ...[
              // 邮箱注册：邮箱
              LoginTextField(
                controller: _emailController,
                title: '邮箱'.tr,
                hintText: '请输入邮箱地址'.tr,
                keyboardType: TextInputType.emailAddress,

                onChanged: (value) {
                  // 处理手机号变化
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
            const SizedBox(height: 20),
            CommonButton(
              text: '下一步'.tr,
              enabled: true,
              onPressed: () {
                // 调用发验证码的接口
                if (_registerType == RegisterType.phoneCode) {
                  if (_phoneController.text.isEmpty) {
                    EasyLoading.showError('请先输入手机号'.tr);
                    return;
                  }
                  _getVerifyCode((cid) {
                    Get.to(
                      () => RegisterCodePage(
                        cid: cid,
                        registerType: _registerType,
                        account: _registerType == RegisterType.phoneCode
                            ? _phoneController.text
                            : _emailController.text,
                        invateCode: widget.invateCode,
                        isForget: false,
                      ),
                    );
                  });
                } else if (_registerType == RegisterType.emailCode) {
                  if (_emailController.text.isEmpty) {
                    EasyLoading.showError('请先输入邮箱'.tr);
                    return;
                  }
                  _getEmailVerifyCode((cid) {
                    Get.to(
                      () => RegisterCodePage(
                        cid: cid,
                        registerType: _registerType,
                        account: _registerType == RegisterType.phoneCode
                            ? _phoneController.text
                            : _emailController.text,
                        invateCode: widget.invateCode,
                        isForget: false,
                      ),
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 获取验证码
  void _getVerifyCode(ValueChanged onVerifyCodeSuccess) async {
    // 验证手机号
    if (_phoneController.text.isEmpty) {
      EasyLoading.showError('请先输入手机号'.tr);
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneController.text)) {
      EasyLoading.showError('请输入正确的手机号'.tr);
      return;
    }

    try {
      EasyLoading.show(status: '发送中...'.tr);

      // 调用 Native 获取短信验证码接口
      final result = await _nativeService.imGetCaptcha(
        _phoneController.text,
        type: 'SMS', // CaptchaType: SMS=短信
        scene: 'register', // 使用场景: 注册
      );

      EasyLoading.dismiss();

      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误'.tr;

      if (errorCode == 0) {
        // 保存 captcha_id（从返回的 data 中解析）
        final data = result['data'];
        if (data != null && data.isNotEmpty) {
          // data 应该是 JSON 字符串，解析它
          try {
            final dataMap = json.decode(data);
            _captchaId = dataMap['captcha_id'];
            print('✅ 获取到 captcha_id: $_captchaId');
            onVerifyCodeSuccess(_captchaId);
          } catch (e) {
            print('⚠️ 解析 captcha_id 失败: $e');
          }
        }

        EasyLoading.showSuccess('验证码已发送'.tr);
      } else {
        EasyLoading.showError('${'发送失败'.tr}: $message (code: $errorCode)');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('${'发送失败'.tr}: $e');
    }
  }

  /// 获取邮箱验证码
  void _getEmailVerifyCode(ValueChanged onVerifyCodeSuccess) async {
    // 验证邮箱
    if (_emailController.text.isEmpty) {
      EasyLoading.showError('请先输入邮箱'.tr);
      return;
    }

    if (!RegExp(
      r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$',
    ).hasMatch(_emailController.text)) {
      EasyLoading.showError('请输入正确的邮箱地址'.tr);
      return;
    }

    try {
      EasyLoading.show(status: '发送中...'.tr);

      // 调用 Native 获取邮箱验证码接口
      final result = await _nativeService.imGetCaptcha(
        _emailController.text,
        type: 'EMAIL', // CaptchaType: EMAIL=邮箱
        scene: 'register', // 使用场景: 注册
      );

      EasyLoading.dismiss();

      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误'.tr;

      if (errorCode == 0) {
        // 保存 captcha_id
        final data = result['data'];
        if (data != null && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data);
            _emailCaptchaId = dataMap['captcha_id'];
            print('✅ 获取到邮箱 captcha_id: $_emailCaptchaId');
            onVerifyCodeSuccess(_emailCaptchaId);
          } catch (e) {
            print('⚠️ 解析邮箱 captcha_id 失败: $e');
          }
        }

        EasyLoading.showSuccess('验证码已发送到邮箱'.tr);
      } else {
        EasyLoading.showError('${'发送失败'.tr}: $message (code: $errorCode)');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('${'发送失败'.tr}: $e');
    }
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

  // /// 通用文本输入框
  // Widget _buildTextField({
  //   required TextEditingController controller,
  //   required String label,
  //   required String hint,
  //   required IconData prefixIcon,
  //   bool obscureText = false,
  //   Widget? suffixIcon,
  //   TextInputType? keyboardType,
  //   String? Function(String?)? validator,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       TextFormField(
  //         controller: controller,
  //         obscureText: obscureText,
  //         keyboardType: keyboardType,
  //         decoration: InputDecoration(
  //           hintText: hint,
  //           prefixIcon: Icon(prefixIcon),
  //           suffixIcon: suffixIcon,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: BorderSide(color: Colors.grey.shade300),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: const BorderSide(color: Colors.blue, width: 2),
  //           ),
  //           errorBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: const BorderSide(color: Colors.red),
  //           ),
  //         ),
  //         validator: validator,
  //       ),
  //     ],
  //   );
  // }

  // /// 用户协议勾选
  // Widget _buildTermsCheckbox() {
  //   return Row(
  //     children: [
  //       Checkbox(
  //         value: _agreeTerms,
  //         onChanged: (value) {
  //           setState(() {
  //             _agreeTerms = value ?? false;
  //           });
  //         },
  //         activeColor: Colors.white,
  //         checkColor: Colors.blue,
  //       ),
  //       Expanded(
  //         child: GestureDetector(
  //           onTap: () {
  //             setState(() {
  //               _agreeTerms = !_agreeTerms;
  //             });
  //           },
  //           child: RichText(
  //             text: TextSpan(
  //               style: const TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.white,
  //               ),
  //               children: [
  //                 const TextSpan(text: '我已阅读并同意'),
  //                 TextSpan(
  //                   text: '《用户协议》',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold,
  //                     decoration: TextDecoration.underline,
  //                   ),
  //                 ),
  //                 const TextSpan(text: '和'),
  //                 TextSpan(
  //                   text: '《隐私政策》',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold,
  //                     decoration: TextDecoration.underline,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // /// 注册按钮
  // Widget _buildRegisterButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 50,
  //     child: ElevatedButton(
  //       onPressed: _handleRegister,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.white,
  //         foregroundColor: Colors.blue.shade700,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         elevation: 5,
  //       ),
  //       child: const Text(
  //         '立即注册',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // /// 手机验证码倒计时
  // void _startCountdown() {
  //   Future.delayed(const Duration(seconds: 1), () {
  //     if (_countdown > 0) {
  //       setState(() {
  //         _countdown--;
  //       });
  //       _startCountdown();
  //     }
  //   });
  // }

  // /// 邮箱验证码倒计时
  // void _startEmailCountdown() {
  //   Future.delayed(const Duration(seconds: 1), () {
  //     if (_emailCountdown > 0) {
  //       setState(() {
  //         _emailCountdown--;
  //       });
  //       _startEmailCountdown();
  //     }
  //   });
  // }

  // /// 处理注册
  // void _handleRegister() async {
  //   // 验证用户协议
  //   if (!_agreeTerms) {
  //     EasyLoading.showError('请先阅读并同意用户协议');
  //     return;
  //   }

  //   // 表单验证
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }

  // }
}
