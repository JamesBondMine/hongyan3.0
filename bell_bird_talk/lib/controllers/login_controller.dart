import 'dart:async';
import 'dart:convert';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/user_model.dart';
import '../utils/storage_util.dart';
import '../services/native_bridge.dart';
import 'global_controller.dart';

/// 登录方式枚举
enum LoginType {
  password,   // 账号密码登录
  smsCode,    // 手机验证码登录
  emailCode,  // 邮箱验证码登录
}

/// 登录控制器
class LoginController extends GetxController {
  // 文本控制器
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();  // 邀请码

  static LoginController get to => Get.put(LoginController());
  
  // 状态
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberPassword = false.obs;
  
  // 登录方式
  final Rx<LoginType> loginType = LoginType.smsCode.obs;
  
  // 区号选择
  final RxString selectedCountryCode = '+86'.obs;
  final RxString selectedFlag = '🇨🇳'.obs;
  
  // 手机/邮箱登录模式：true=密码登录，false=验证码登录
  final RxBool smsUsePassword = true.obs;      // 手机登录默认使用密码
  final RxBool emailUsePassword = true.obs;    // 邮箱登录默认使用密码
  
  // 验证码相关
  final RxInt countdown = 0.obs;
  final RxBool isSendingCode = false.obs;
  Timer? _countdownTimer;
  String? _captchaId; // 验证码ID
  
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final IOSNativeService _nativeBridge = IOSNativeService();

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    emailController.dispose();
    codeController.dispose();
    inviteCodeController.dispose();
    _countdownTimer?.cancel();
    super.onClose();
  }

  /// 加载保存的账号密码
  Future<void> _loadSavedCredentials() async {
    // 加载账号密码登录的凭据
    final savedUsername = StorageUtil().getString('saved_username');
    final savedPassword = StorageUtil().getString('saved_password');
    
    if (savedUsername != null && savedPassword != null) {
      usernameController.text = savedUsername;
      rememberPassword.value = true;
    }
    
    // 加载手机号密码登录的凭据
    final savedPhone = StorageUtil().getString('saved_phone');
    if (savedPhone != null) {
      phoneController.text = savedPhone;
    }
    
    // 加载邮箱密码登录的凭据
    final savedEmail = StorageUtil().getString('saved_email');
    if (savedEmail != null) {
      emailController.text = savedEmail;
    }
    
    // 根据默认登录方式加载密码
    _loadPasswordForCurrentType();
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  /// 切换登录方式
  void switchLoginType(LoginType type) {
    loginType.value = type;
    // 清空验证码相关
    codeController.clear();
    _captchaId = null;
    
    // 根据登录方式加载保存的密码
    _loadPasswordForCurrentType();
  }
  
  /// 根据当前登录方式加载保存的密码
  void _loadPasswordForCurrentType() {
    passwordController.clear();
    
    switch (loginType.value) {
      case LoginType.password:
        final savedPassword = StorageUtil().getString('saved_password');
        if (savedPassword != null) {
          passwordController.text = savedPassword;
        }
        break;
      case LoginType.smsCode:
        if (smsUsePassword.value) {
          final savedPhonePassword = StorageUtil().getString('saved_phone_password');
          if (savedPhonePassword != null) {
            passwordController.text = savedPhonePassword;
          }
        }
        break;
      case LoginType.emailCode:
        if (emailUsePassword.value) {
          final savedEmailPassword = StorageUtil().getString('saved_email_password');
          if (savedEmailPassword != null) {
            passwordController.text = savedEmailPassword;
          }
        }
        break;
    }
  }
  
  /// 切换手机登录模式（密码/验证码）
  void toggleSmsLoginMode() {
    smsUsePassword.value = !smsUsePassword.value;
    // 清空相关字段
    passwordController.clear();
    codeController.clear();
    _captchaId = null;
    
    // 如果切换到密码模式，加载保存的密码
    if (smsUsePassword.value) {
      final savedPhonePassword = StorageUtil().getString('saved_phone_password');
      if (savedPhonePassword != null) {
        passwordController.text = savedPhonePassword;
      }
    }
  }
  
  /// 切换邮箱登录模式（密码/验证码）
  void toggleEmailLoginMode() {
    emailUsePassword.value = !emailUsePassword.value;
    // 清空相关字段
    passwordController.clear();
    codeController.clear();
    _captchaId = null;
    
    // 如果切换到密码模式，加载保存的密码
    if (emailUsePassword.value) {
      final savedEmailPassword = StorageUtil().getString('saved_email_password');
      if (savedEmailPassword != null) {
        passwordController.text = savedEmailPassword;
      }
    }
  }

  /// 发送忘记密码的验证码
  Future sendForgetVerificationCode(ValueChanged success) async {
    String target = '';
    String codeType = '';
    
    if (loginType.value == LoginType.smsCode) {
      target = phoneController.text.trim();
      codeType = 'SMS';
      if (target.isEmpty) {
        EasyLoading.showError('请输入手机号');
        return '';
      }
      if (!_isValidPhone(target)) {
        EasyLoading.showError('请输入正确的手机号');
        return '';
      }
    } else if (loginType.value == LoginType.emailCode) {
      target = emailController.text.trim();
      codeType = 'EMAIL';
      if (target.isEmpty) {
        EasyLoading.showError('请输入邮箱');
        return '';
      }
      if (!_isValidEmail(target)) {
        EasyLoading.showError('请输入正确的邮箱地址');
        return '';
      }
    }
    
    try {
      isSendingCode.value = true;
      EasyLoading.show(status: '发送验证码中...');
      
      // 调用原生发送验证码
      final result = await _nativeBridge.imGetCaptcha(
        target,
        type: codeType,
        scene: 'reset_password', // 登录场景
      );
      
      print('📬 验证码发送结果: $result');
      EasyLoading.dismiss();
      if (result['errorCode'] == 0) {
        // 解析 data 字段获取 captcha_id
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final dataMap = json.decode(dataStr) as Map<String, dynamic>;
            _captchaId = dataMap['captcha_id'] as String?;

            print('📝 验证码ID: $_captchaId');
            success(_captchaId);
            return _captchaId ?? '';
          } catch (e) {
            print('⚠️ 解析验证码数据失败: $e');
            return '';
          }
        }
        
        EasyLoading.showSuccess('验证码已发送');
      } else {
        EasyLoading.showError(result['message'] ?? '发送失败');
        return '';
      }
    } catch (e) {
      print('发送验证码错误: $e');
      EasyLoading.showError('发送验证码失败');
      return '';
    } finally {
      isSendingCode.value = false;
      
    }
    return '';
  }



  /// 发送验证码
  Future<void> sendVerificationCode() async {
    String target = '';
    String codeType = '';
    
    if (loginType.value == LoginType.smsCode) {
      target = phoneController.text.trim();
      codeType = 'SMS';
      if (target.isEmpty) {
        EasyLoading.showError('请输入手机号');
        return;
      }
      if (!_isValidPhone(target)) {
        EasyLoading.showError('请输入正确的手机号');
        return;
      }
    } else if (loginType.value == LoginType.emailCode) {
      target = emailController.text.trim();
      codeType = 'EMAIL';
      if (target.isEmpty) {
        EasyLoading.showError('请输入邮箱');
        return;
      }
      if (!_isValidEmail(target)) {
        EasyLoading.showError('请输入正确的邮箱地址');
        return;
      }
    }
    
    try {
      isSendingCode.value = true;
      EasyLoading.show(status: '发送验证码中...');
      
      // 调用原生发送验证码
      final result = await _nativeBridge.imGetCaptcha(
        target,
        type: codeType,
        scene: 'login', // 登录场景
      );
      
      print('📬 验证码发送结果: $result');
      EasyLoading.dismiss();
      if (result['errorCode'] == 0) {
        // 解析 data 字段获取 captcha_id
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final dataMap = json.decode(dataStr) as Map<String, dynamic>;
            _captchaId = dataMap['captcha_id'] as String?;
            print('📝 验证码ID: $_captchaId');
          } catch (e) {
            print('⚠️ 解析验证码数据失败: $e');
          }
        }
        
        EasyLoading.showSuccess('验证码已发送');
        _startCountdown();
      } else {
        EasyLoading.showError(result['message'] ?? '发送失败');
      }
    } catch (e) {
      print('发送验证码错误: $e');
      EasyLoading.showError('发送验证码失败');
    } finally {
      isSendingCode.value = false;
    }
  }
  
  /// 开始倒计时
  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }
  
  /// 验证手机号格式
  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }
  
  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// 登录
  Future<void> login() async {
    switch (loginType.value) {
      case LoginType.password:
        await _loginWithPassword();
        break;
      case LoginType.smsCode:
        if (smsUsePassword.value) {
          await _loginWithPhonePassword();
        } else {
          await _loginWithSMS();
        }
        break;
      case LoginType.emailCode:
        if (emailUsePassword.value) {
          await _loginWithEmailPassword();
        } else {
          await _loginWithEmail();
        }
        break;
    }
  }
  
  /// 密码登录
  Future<void> _loginWithPassword() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      EasyLoading.showError('请输入用户名');
      return;
    }
    if (password.isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }

    try {
      isLoading.value = true;
      EasyLoading.show(status: '登录中...');

      // 调用原生密码登录
      final inviteCode = inviteCodeController.text.trim();
      print('🔐 密码登录: accountId=$username, password=$password, inviteCode=$inviteCode');
      
      final result = await _nativeBridge.imLoginWithPassword(
        accountId: username,
        password: password,
        bizCode: inviteCode.isNotEmpty ? inviteCode : null,
      );
      
      print('🔐 密码登录结果: $result');
      
      await _handleLoginResult(result, username);

      String userId = result['data']['user_id'] as String? ?? '';
      if (userId.isNotEmpty) {
        GlobalController.to.logMyPublicInfo(userId);
      }
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 手机+密码登录
  Future<void> _loginWithPhonePassword() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty) {
      EasyLoading.showError('请输入手机号');
      return;
    }
    if (password.isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }

    try {
      isLoading.value = true;
      EasyLoading.show(status: '登录中...');

      final inviteCode = inviteCodeController.text.trim();
      print('📱 手机密码登录: phone=$phone, password=$password, inviteCode=$inviteCode');
      
      final result = await _nativeBridge.imLoginWithPhonePassword(
        phone: phone,
        password: password,
        bizCode: inviteCode.isNotEmpty ? inviteCode : null,
      );
      
      print('📱 手机密码登录结果: $result');
      
      await _handleLoginResult(result, phone);
      
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 短信验证码登录
  Future<void> _loginWithSMS() async {
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();

    if (phone.isEmpty) {
      EasyLoading.showError('请输入手机号');
      return;
    }
    if (code.isEmpty) {
      EasyLoading.showError('请输入验证码');
      return;
    }
    try {
      isLoading.value = true;
      EasyLoading.show(status: '登录中...');

      // 调用原生短信登录
      final inviteCode = inviteCodeController.text.trim();
      print('📱 短信登录: phone=$phone, code=$code, captchaId=$_captchaId, inviteCode=$inviteCode');
      
      final result = await _nativeBridge.imLoginWithSMS(
        phone: phone,
        code: code,
        captchaId: _captchaId!,
        bizCode: inviteCode.isNotEmpty ? inviteCode : null,
      );
      
      print('📱 短信登录结果: $result');
      
      await _handleLoginResult(result, phone);

      
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 邮箱+密码登录
  Future<void> _loginWithEmailPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      EasyLoading.showError('请输入邮箱');
      return;
    }
    if (password.isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }

    try {
      isLoading.value = true;
      EasyLoading.show(status: '登录中...');

      final inviteCode = inviteCodeController.text.trim();
      print('📧 邮箱密码登录: email=$email, password=$password, inviteCode=$inviteCode');
      
      final result = await _nativeBridge.imLoginWithEmailPassword(
        email: email,
        password: password,
        bizCode: inviteCode.isNotEmpty ? inviteCode : null,
      );
      
      print('📧 邮箱密码登录结果: $result');
      
      await _handleLoginResult(result, email);

      
      
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 邮箱验证码登录
  Future<void> _loginWithEmail() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (email.isEmpty) {
      EasyLoading.showError('请输入邮箱');
      return;
    }
    if (code.isEmpty) {
      EasyLoading.showError('请输入验证码');
      return;
    }
    // if (_captchaId == null) {
    //   EasyLoading.showError('请先获取验证码');
    //   return;
    // }

    try {
      isLoading.value = true;
      EasyLoading.show(status: '登录中...');

      // 调用原生邮箱登录
      final inviteCode = inviteCodeController.text.trim();
      print('📧 邮箱登录: email=$email, code=$code, captchaId=$_captchaId, inviteCode=$inviteCode');
      
      final result = await _nativeBridge.imLoginWithEmail(
        email: email,
        code: code,
        captchaId: _captchaId!,
        bizCode: inviteCode.isNotEmpty ? inviteCode : null,
      );
      
      print('📧 邮箱登录结果: $result');
      
      await _handleLoginResult(result, email);
      
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 处理登录结果
  Future<void> _handleLoginResult(Map<String, dynamic> result, String account) async {
    if (result['errorCode'] == 0) {
      // 解析用户数据
      final data = result['data'];
      print('📦 登录返回数据: $data');
      
      // 尝试解析用户信息
      UserModel? user;
      String token = "";
      String refresh_token = "";
      
      if (data != null && data is String && data.isNotEmpty) {
        try {
          // 解析 JSON 数据
          final dataMap = json.decode(data) as Map<String, dynamic>;
          print('📝 登录返回数据解析: $dataMap');


          print(" ⚠️⚠️⚠️⚠️⚠️⚠️⚠️ 登录原始信息: Token=${dataMap['token']  ?? ''}");
          
          // 获取 token
          token = dataMap['token']  ?? '';
          refresh_token = dataMap['refresh_token']  ?? '';
    
          
          // 获取用户信息
          final userMap = dataMap['user'] as Map<String, dynamic>?;
          if (userMap != null) {
            user = UserModel.fromJson(userMap);
            print('👤 用户信息: ${user.nickname}');
            String userId = user.id ;
      if (userId.isNotEmpty) {
        GlobalController.to.logMyPublicInfo(userId);
      }
          }
        } catch (e) {
          print('⚠️ 解析登录数据失败: $e');
        }
      }
      
      // 如果没有解析到用户信息，创建一个基本的用户对象
      user ??= UserModel(
        id: result['reqId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        username: account,
        nickname: account,
        avatar: '',
        phone: loginType.value == LoginType.smsCode ? account : '',
        email: loginType.value == LoginType.emailCode ? account : '',
        gender: 0,
        signature: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      

      print(" ⚠️⚠️⚠️⚠️⚠️⚠️⚠️ 解析登录信息: Token=$token");
      
      // 保存登录信息
      await _globalCtrl.saveLoginInfo(token, refresh_token, user);
      
      // 保存账号密码（根据登录方式）
      await _saveCredentialsForCurrentType();
      
      EasyLoading.showSuccess('登录成功');
      
      // 跳转到首页
      Get.offAllNamed('/home');
    } else {
      EasyLoading.showError(result['message'] ?? '登录失败');
    }
  }

  /// 根据当前登录方式保存账号密码
  Future<void> _saveCredentialsForCurrentType() async {
    switch (loginType.value) {
      case LoginType.password:
        // 账号密码登录：根据"记住密码"选项保存
        if (rememberPassword.value) {
          await _saveCredentials(usernameController.text.trim(), passwordController.text.trim());
        }
        break;
      case LoginType.smsCode:
        // 手机登录
        final phone = phoneController.text.trim();
        if (phone.isNotEmpty) {
          await StorageUtil().setString('saved_phone', phone);
        }
        // 如果是密码模式，保存密码
        if (smsUsePassword.value) {
          final password = passwordController.text.trim();
          if (password.isNotEmpty) {
            await StorageUtil().setString('saved_phone_password', password);
            print('💾 已保存手机号密码: phone=$phone');
          }
        }
        break;
      case LoginType.emailCode:
        // 邮箱登录
        final email = emailController.text.trim();
        if (email.isNotEmpty) {
          await StorageUtil().setString('saved_email', email);
        }
        // 如果是密码模式，保存密码
        if (emailUsePassword.value) {
          final password = passwordController.text.trim();
          if (password.isNotEmpty) {
            await StorageUtil().setString('saved_email_password', password);
            print('💾 已保存邮箱密码: email=$email');
          }
        }
        break;
    }
  }

  /// 保存账号密码
  Future<void> _saveCredentials(String username, String password) async {
    await StorageUtil().setString('saved_username', username);
    await StorageUtil().setString('saved_password', password);
  }

  /// 清除保存的账号密码
  Future<void> _clearCredentials() async {
    await StorageUtil().remove('saved_username');
    await StorageUtil().remove('saved_password');
  }



  /// 重置密码
  Future<void> resetPassword(String phone, String email, String code, String password, String captchaId) async {

    EasyLoading.show(status: '正在重置密码...');

    try {
      final result = await _nativeBridge.imResetPassword(
        phone: phone,
        email: email,
        code: code,
        captchaId: captchaId,
        newPassword: password,
      );
      
      print('🔐 重置密码结果: $result');
      EasyLoading.dismiss();
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('密码重置成功');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAll(LoginPage());
      } else {
        EasyLoading.showError(result['message'] ?? '重置失败');
      }
    } catch (e) {
      print('重置密码错误: $e');
      EasyLoading.dismiss();
      EasyLoading.showError('重置失败，请稍后重试');
    }
  }
}
