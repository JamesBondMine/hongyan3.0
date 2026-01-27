import 'dart:ui';
import 'package:bell_bird_talk/config/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'pages/native_demo_page.dart';
import 'pages/framework_test_page.dart';
import 'pages/login/login_page.dart';
import 'pages/home_page.dart';
import 'pages/friends/pages/friends_home_page.dart';
import 'pages/friends/add_friend_page.dart';
import 'utils/storage_util.dart';
import 'controllers/global_controller.dart';
import 'config/translations.dart';
import 'utils/shader_warmup.dart';

void main() {
  Global.init(() async {
    // 配置 EasyLoading
    _configEasyLoading();

    // 初始化 Flutter binding
    WidgetsFlutterBinding.ensureInitialized();
    
    // 配置 Shader 预热
    // 这会在第一帧渲染之前预热常用的 shader，减少首次渲染卡顿
    PaintingBinding.shaderWarmUp = const AppShaderWarmUp();

    runApp(const MyApp());
  });
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

  /// 将系统语言映射到应用支持的语言
  String _mapSystemLocaleToAppLocale(Locale systemLocale) {
    final languageCode = systemLocale.languageCode.toLowerCase();
    final countryCode = systemLocale.countryCode?.toUpperCase() ?? '';
    
    // 构建完整的 locale 字符串
    final localeStr = countryCode.isNotEmpty 
        ? '${languageCode}_$countryCode' 
        : languageCode;
    
    // 检查应用是否支持该语言
    for (var lang in AppLanguages.languages) {
      if (lang.locale == localeStr) {
        return localeStr;
      }
      // 如果完整匹配失败，尝试只匹配语言代码
      if (lang.locale.startsWith('${languageCode}_')) {
        return lang.locale;
      }
    }
    
    // 如果不支持，返回默认中文
    return 'zh_CN';
  }

  /// 获取系统语言
  Locale _getSystemLocale() {
    final systemLocales = PlatformDispatcher.instance.locales;
    if (systemLocales.isNotEmpty) {
      return systemLocales.first;
    }
    // 如果没有系统语言，返回默认中文
    return const Locale('zh', 'CN');
  }

  /// 获取初始语言设置
  Locale _getInitialLocale() {
    // 优先使用存储的语言设置
    final storedLocaleStr = StorageUtil().getString('app_language');
    
    if (storedLocaleStr != null && storedLocaleStr.isNotEmpty) {
      // 有存储的语言设置，使用它
      final parts = storedLocaleStr.split('_');
      return Locale(parts[0], parts.length > 1 ? parts[1] : '');
    } else {
      // 没有存储的语言设置，跟随系统语言
      final systemLocale = _getSystemLocale();
      final appLocaleStr = _mapSystemLocaleToAppLocale(systemLocale);
      final parts = appLocaleStr.split('_');
      print('🌐 未设置应用语言，跟随系统语言: $systemLocale -> $appLocaleStr');
      return Locale(parts[0], parts.length > 1 ? parts[1] : '');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取初始语言设置
    final initialLocale = _getInitialLocale();
    
    return ScreenUtilInit(
      designSize: GetPlatform.isMobile ? const Size(375, 812) : const Size(1080, 1920), // 设计稿尺寸，根据你的设计稿调整
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: '铃鸟聊天',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            fontFamily: 'PingFang',
          ),
          navigatorObservers: [TUICallKit.navigatorObserver],
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
          locale: initialLocale,
          fallbackLocale: const Locale('zh', 'CN'),
          // 使用启动页面
          home: const SplashPage(),
          builder: EasyLoading.init(),
          // 路由配置
          getPages: [
            GetPage(name: '/login', page: () => const LoginPage()),
            GetPage(name: '/home', page: () => const HomePage()),
            GetPage(name: '/friends', page: () => const FriendsHomePage()),
            GetPage(name: '/add-friend', page: () => AddFriendPage()),
            GetPage(name: '/demo', page: () => const NativeDemoPage()),
            GetPage(name: '/test', page: () => const FrameworkTestPage()),
          ],
          // 默认转场动画
          defaultTransition: Transition.cupertino,
          // 调试标签
          debugShowCheckedModeBanner: false,
        );
      },
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
        setState(() => _statusText = '登录成功');
        await Future.delayed(const Duration(milliseconds: 300));
        Get.off(() => const HomePage());
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
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset('assets/img/common/logo_launch.png'),
            ),

            const SizedBox(height: 32),

            // // App 名称
            // const Text(
            //   '铃鸟聊天',
            //   style: TextStyle(
            //     fontSize: 32,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),

            const SizedBox(height: 48),

            // 加载指示器
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 16),

            Text(
              _statusText,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
