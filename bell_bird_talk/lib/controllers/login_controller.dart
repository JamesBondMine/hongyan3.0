import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import '../services/api_service.dart'; // 真实环境使用
import '../models/user_model.dart';
import '../utils/storage_util.dart';
// import '../config/constants.dart'; // 真实环境使用
import 'global_controller.dart';

/// 登录控制器
class LoginController extends GetxController {
  // 文本控制器
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // 状态
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberPassword = false.obs;
  
  final GlobalController _globalCtrl = Get.find<GlobalController>();

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// 加载保存的账号密码
  Future<void> _loadSavedCredentials() async {
    final savedUsername = StorageUtil().getString('saved_username');
    final savedPassword = StorageUtil().getString('saved_password');
    
    if (savedUsername != null && savedPassword != null) {
      usernameController.text = savedUsername;
      passwordController.text = savedPassword;
      rememberPassword.value = true;
    }
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// 登录
  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // 验证输入
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

      // 调用登录接口（这里使用模拟登录）
      await _mockLogin(username, password);

      // 真实环境取消注释下面的代码
      // final result = await ApiService().login(
      //   username: username,
      //   password: password,
      // );
      //
      // if (result.isSuccess) {
      //   final token = result.data!['token'] as String;
      //   final userData = result.data!['user'] as Map<String, dynamic>;
      //   final user = UserModel.fromJson(userData);
      //
      //   // 保存登录信息
      //   await _globalCtrl.saveLoginInfo(token, user);
      //
      //   // 保存账号密码
      //   if (rememberPassword.value) {
      //     await _saveCredentials(username, password);
      //   } else {
      //     await _clearCredentials();
      //   }
      //
      //   EasyLoading.showSuccess('登录成功');
      //
      //   // 跳转到首页
      //   Get.offAllNamed('/home');
      // } else {
      //   EasyLoading.showError(result.message);
      // }
    } catch (e) {
      print('登录错误: $e');
      EasyLoading.showError('登录失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  /// 模拟登录（用于测试）
  Future<void> _mockLogin(String username, String password) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    // 验证账号密码
    if (username == 'test' && password == '123456') {
      // 创建模拟用户
      final user = UserModel(
        id: '1',
        username: username,
        nickname: '测试用户',
        avatar: 'https://via.placeholder.com/150',
        phone: '13800138000',
        email: 'test@example.com',
        gender: 1,
        signature: '这是一个测试账号',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 模拟 Token
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      // 保存登录信息
      await _globalCtrl.saveLoginInfo(token, user);

      // 保存账号密码
      if (rememberPassword.value) {
        await _saveCredentials(username, password);
      } else {
        await _clearCredentials();
      }

      EasyLoading.showSuccess('登录成功');

      // 跳转到首页
      Get.offAllNamed('/home');
    } else {
      throw Exception('用户名或密码错误');
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
}

