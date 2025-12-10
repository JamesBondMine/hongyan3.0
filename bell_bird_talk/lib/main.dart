import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'pages/native_demo_page.dart';
import 'pages/framework_test_page.dart';
import 'pages/login/login_page.dart';
import 'pages/home_page.dart';
import 'pages/friends/friends_page.dart';
import 'pages/friends/add_friend_page.dart';
import 'utils/storage_util.dart';
import 'controllers/global_controller.dart';
import 'config/translations.dart';

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
      // 多语言配置
      translations: AppTranslations(),
      locale: const Locale('zh', 'CN'),
      fallbackLocale: const Locale('zh', 'CN'),
      // 使用启动页面
      home: const SplashPage(),
      builder: EasyLoading.init(),
      // 路由配置
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/friends', page: () => const FriendsPage()),
        GetPage(name: '/add-friend', page: () => const AddFriendPage()),
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

/// 启动页面 - 处理初始化逻辑
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusText = '正在初始化...';
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 等待一小段时间，确保 GetX 初始化完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 获取全局控制器
      final globalCtrl = Get.find<GlobalController>();
      
      // 等待 SDK 初始化完成（最多等待 3 秒）
      setState(() => _statusText = '正在初始化 SDK...');
      await Future.any([
        Future.delayed(const Duration(seconds: 3)),
        Future(() async {
          while (globalCtrl.imsdkStatus.value == '正在初始化...' || 
                 globalCtrl.imsdkStatus.value == '正在启动网络服务...') {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }),
      ]);
      
      // 检查是否需要自动登录
      if (globalCtrl.needAutoLogin()) {
        // 有保存的 Token，尝试自动登录
        setState(() => _statusText = '正在自动登录...');
        print('📱 检测到本地 Token，开始自动登录...');
        
        final autoLoginSuccess = await globalCtrl.autoLoginWithToken();
        
        if (autoLoginSuccess) {
          // 自动登录成功，跳转首页
          print('✅ 自动登录成功，跳转首页');
          setState(() => _statusText = '登录成功');
          await Future.delayed(const Duration(milliseconds: 300));
          Get.off(() => const HomePage());
        } else {
          // 自动登录失败，跳转登录页
          print('❌ 自动登录失败，跳转登录页');
          setState(() => _statusText = '登录已过期');
          await Future.delayed(const Duration(milliseconds: 500));
          Get.off(() => const LoginPage());
        }
      } else {
        // 没有保存的 Token，直接跳转登录页
        print('📱 没有本地 Token，跳转登录页');
        Get.off(() => const LoginPage());
      }
    } catch (e) {
      print('❌ 初始化错误: $e');
      // 出错也跳转到登录页
      Get.off(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 或 App 图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App 名称
            const Text(
              '铃鸟聊天',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 加载指示器
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
