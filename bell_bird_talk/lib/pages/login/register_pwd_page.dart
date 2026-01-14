import 'dart:convert';
import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:bell_bird_talk/pages/login/register_info_page.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/models/user_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 注册页面
class RegisterPwdPage extends StatefulWidget {
    RegisterPwdPage({super.key, 
   this.registerType = RegisterType.phoneCode,
   this.account = '',
    this.code = '',
    this.cid = '',
     this.invateCode = '',
      this.isForget = false,
  });

  String account = '';
  String code = '';
  String cid = '';
  String invateCode = '';
  RegisterType registerType = RegisterType.phoneCode;
  bool isForget = false;


  @override
  State<RegisterPwdPage> createState() => _RegisterPwdPageState();
}

/// 注册方式枚举
enum RegisterType {
  phoneCode,       // 手机验证码注册
  emailCode,       // 邮箱验证码注册
}

class _RegisterPwdPageState extends State<RegisterPwdPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _inviteCodeController = TextEditingController();
  final _nativeService = IOSNativeService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  String? _captchaId; // 存储手机验证码 ID
  String? _emailCaptchaId; // 存储邮箱验证码 ID

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Logo 和标题
                        _buildHeader(),
                        const SizedBox(height: 20),
                        
                        // 注册表单
                        _buildRegisterForm(),
                        const SizedBox(height: 6),
                        Text(
          '密码长度6-16位，需包含数字、字母、特殊符号中的两种',
          style: TextStyle(
            fontSize: 12,
            color: GbsColors.des9Color,
          ),
        ),
                        const SizedBox(height: 50),
                   
                        
                        
                        // 注册按钮
                        _buildRegisterButton(),
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

        const SizedBox(height: 8),

        // 副标题
        Text(
          '设置登录密码',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.9),
          ),
        ),

        // 副标题
        Text(widget.account,
          style: TextStyle(
            fontSize: 20,
            color: GbsColors.titleColor,
          ),
        ),

        
      ],
    ));
  }

  /// 注册表单
  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Container(
        // padding: const EdgeInsets.all(24),
       
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            LoginTextField(
      controller: _passwordController,
      title: '登录密码',
      hintText: '请输入密码（6-20位',
       obscureText: _obscurePassword,
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
      // validator: (value) {
      //   if (value == null || value.isEmpty) {
      //     return '请输入密码';
      //   }
      //   if (value.length < 6 || value.length > 20) {
      //     return '密码长度为6-20位';
      //   }
      //   return null;
      // },
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    ),
            
            // 密码输入框（两种方式都需要）
            // _buildTextField(
            //   controller: _passwordController,
            //   label: '密码',
            //   hint: '请输入密码（6-20位）',
            //   prefixIcon: Icons.lock_outline,
            //   obscureText: _obscurePassword,
            //   suffixIcon: IconButton(
            //     icon: Icon(
            //       _obscurePassword ? Icons.visibility_off : Icons.visibility,
            //       color: Colors.grey,
            //     ),
            //     onPressed: () {
            //       setState(() {
            //         _obscurePassword = !_obscurePassword;
            //       });
            //     },
            //   ),
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return '请输入密码';
            //     }
            //     if (value.length < 6 || value.length > 20) {
            //       return '密码长度为6-20位';
            //     }
            //     return null;
            //   },
            // ),
            
            const SizedBox(height: 20),
            
            // 确认密码输入框（两种方式都需要）

            LoginTextField(
      controller: _confirmPasswordController,
      title: '二次确认',
      hintText: '请输入密码（6-20位',
       obscureText: _obscureConfirmPassword,
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
      //  validator: (value) {
      //           if (value == null || value.isEmpty) {
      //             return '请再次输入密码';
      //           }
      //           if (value != _passwordController.text) {
      //             return '两次输入的密码不一致';
      //           }
      //           return null;
      //         },
              ),

            // _buildTextField(
            //   controller: _confirmPasswordController,
            //   label: '确认密码',
            //   hint: '请再次输入密码',
            //   prefixIcon: Icons.lock_outline,
            //   obscureText: _obscureConfirmPassword,
            //   suffixIcon: IconButton(
            //     icon: Icon(
            //       _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            //       color: Colors.grey,
            //     ),
            //     onPressed: () {
            //       setState(() {
            //         _obscureConfirmPassword = !_obscureConfirmPassword;
            //       });
            //     },
            //   ),
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return '请再次输入密码';
            //     }
            //     if (value != _passwordController.text) {
            //       return '两次输入的密码不一致';
            //     }
            //     return null;
            //   },
            // ),
            
       
          ],
        ),
      ),
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

  /// 注册按钮
  Widget _buildRegisterButton() {
    return CommonButton(text:    '确认'.tr,
    enabled: true,
     onPressed: (){
      if (widget.isForget) {
        resetPassword();
        return;
      }
      _handleRegister();
     });
  }

  // 重置密码
  Future<void> resetPassword() async {
    await LoginController.to.resetPassword(widget.registerType  == RegisterType.phoneCode ? widget.account : '', widget.registerType  == RegisterType.emailCode ? widget.account : '', widget.code, _passwordController.text, widget.cid);
  
  }
/// 处理注册
  void _handleRegister() async {
    // 表单验证
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      EasyLoading.show(status: '注册中...');
      
      // 构建注册数据
      Map<String, dynamic> registerData = {};
      
      if (widget.registerType == RegisterType.phoneCode) {
        // 手机验证码注册
        registerData = {
          'register_type': 'phone', // 注册方式：手机
          'phone': widget.account,
          'password': _passwordController.text,
        };
        
        // 添加验证码信息（如果有 captcha_id）
        if (widget.cid != null ) {
          registerData['captcha'] = {
            'captcha_id': widget.cid,
            'answer': widget.code,
          };
        }
        
        // 添加邀请码（如果有）
        if (_inviteCodeController.text.isNotEmpty) {
          registerData['biz_code'] = _inviteCodeController.text;
        }
      } else if (widget.registerType == RegisterType.emailCode) {
        // 邮箱验证码注册
        registerData = {
          'account_id': widget.account,
          'register_type': 'email', // 注册方式：邮箱
          'email': widget .account,
          'password': _passwordController.text,
        };
        
        // 添加验证码信息（如果有 captcha_id）
        if (widget.cid != null) {
          registerData['captcha'] = {
            'captcha_id': widget.cid,
            'answer': widget.code,
          };
        }
        
        // 添加邀请码（如果有）
        if (_inviteCodeController.text.isNotEmpty) {
          registerData['biz_code'] = widget.invateCode;
        }
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
              // 使用 Token 自动登录，确保 SDK 状态正确
              EasyLoading.show(status: '正在登录...');
              // final loginSuccess = await globalController.autoLoginWithToken();
              // EasyLoading.dismiss();
              // if (loginSuccess) {
                print('✅ Token 自动登录成功');
                // 延迟后跳转到设置用户信息页
                Get.to(() =>  RegisterInfoPage(loginWithToken: true, data:dataMap));
                EasyLoading.showSuccess('注册成功');
              // } else {
              //   print('⚠️ Token 自动登录失败，仍跳转到登录'); 
              //   EasyLoading.showSuccess('注册成功');
              //   await Future.delayed(const Duration(milliseconds: 800));
              //   // Get.offAll(LoginPage());
              //   // 延迟后跳转到设置用户信息页
              //   Get.to(() =>  RegisterInfoPage(loginWithToken: false,data: {}));
              // }
              return;
            }
          } catch (e) {
            print('⚠️ 解析注册返回数据失败: $e');
          }
        }
        EasyLoading.showError('注册失败: $message (code: $errorCode)');
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

