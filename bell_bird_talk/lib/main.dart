import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'pages/native_demo_page.dart';
import 'pages/framework_test_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'utils/storage_util.dart';
import 'controllers/global_controller.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 初始化本地存储
  await StorageUtil.init();
  
  // 初始化全局控制器
  Get.put(GlobalController());
  
  // 配置 EasyLoading
  _configEasyLoading();
  
  runApp(const MyApp());
}

/// 配置 EasyLoading
void _configEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black.withOpacity(0.7)
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取全局控制器检查登录状态
    final globalCtrl = Get.find<GlobalController>();
    
    return GetMaterialApp(
      title: '铃鸟聊天',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'PingFang',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      // 根据登录状态决定初始页面
      home: Obx(() => globalCtrl.isLoggedIn.value 
          ? const HomePage() 
          : const LoginPage()),
      builder: EasyLoading.init(),
      // 路由配置
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/demo', page: () => const NativeDemoPage()),
        GetPage(name: '/test', page: () => const FrameworkTestPage()),
      ],
      // 默认转场动画
      defaultTransition: Transition.cupertino,
      // 调试标签
      debugShowCheckedModeBanner: false,
    );
  }
}

// 原来的欢迎页面已被 LoginPage 和 HomePage 替代
// 如果需要可以保留作为引导页
